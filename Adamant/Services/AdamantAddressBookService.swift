//
//  AdamantAddressBookService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 24/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Clibsodium
import Combine
import CommonKit

@MainActor
final class AdamantAddressBookService: AddressBookService {
    let addressBookKey = "contact_list"
    let waitTime: TimeInterval = 20.0 // in sec
    
    // MARK: - Dependencies
    
    private let apiService: ApiService
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    private let dialogService: DialogService
    
    // MARK: - Properties
    
    var addressBook: [String: String] = [:]
    
    private(set) var hasChanges = false
    
    private var removedNames = [String:String]()
    
    private var savingBookTaskId = UIBackgroundTaskIdentifier.invalid
    private var savingBookOnLogoutTaskId = UIBackgroundTaskIdentifier.invalid
    
    private var notificationsSet: Set<AnyCancellable> = []
    
    // MARK: - Lifecycle
    nonisolated init(
        apiService: ApiService,
        adamantCore: AdamantCore,
        accountService: AccountService,
        dialogService: DialogService
    ) {
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.accountService = accountService
        self.dialogService = dialogService
        
        Task {
            await addObservers()
        }
    }
    
    // MARK: Observers
    
    private func addObservers() {
        // Update on login
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn)
            .sink { _ in
                Task { [weak self] in
                    _ = await self?.update()
                }
            }
            .store(in: &notificationsSet)
        
        // Save on logout
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userWillLogOut)
            .sink { _ in
                Task { [weak self] in
                    _ = await self?.userWillLogOut()
                }
            }
            .store(in: &notificationsSet)
        
        // Clean on logout
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut)
            .sink { _ in
                Task { [weak self] in
                    _ = await self?.userLoggedOut()
                }
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: - Observer Actions
    
    private func userWillLogOut() async {
        guard hasChanges else {
            return
        }
        
        savingBookOnLogoutTaskId = UIApplication.shared.beginBackgroundTask { [unowned self] in
            UIApplication.shared.endBackgroundTask(self.savingBookOnLogoutTaskId)
            self.savingBookOnLogoutTaskId = .invalid
        }
        
        _ = try? await saveAddressBook(self.addressBook)
        
        UIApplication.shared.endBackgroundTask(savingBookOnLogoutTaskId)
        savingBookOnLogoutTaskId = .invalid
    }
    
    private func userLoggedOut() async {
        hasChanges = false
        
        addressBook.removeAll()
    }
    
    // MARK: - Setting
    
    @MainActor func getName(for key: String) -> String? {
        return addressBook[key]?.checkAndReplaceSystemWallets()
    }
    
    @MainActor func getName(for partner: BaseAccount?) -> String? {
        guard let partenerAddress = partner?.address else {
            return nil
        }
        
        return partner?.name?.checkAndReplaceSystemWallets() ?? getName(for: partenerAddress)
    }
    
    func set(name: String, for address: String) async {
        guard addressBook[address] == nil || addressBook[address] != name else {
            return
        }
        
        let changes: [AddressBookChange]
        
        if name.count > 0 {
            if let prevName = addressBook[address] {
                if prevName == name {
                    return
                }
                
                changes = [AddressBookChange.updated(address: address, name: name)]
            } else {
                changes = [AddressBookChange.newName(address: address, name: name)]
            }
            
            addressBook[address] = name
        } else if let prevName = addressBook[address] {
            addressBook.removeValue(forKey: address)
            removedNames[address] = prevName
            changes = [AddressBookChange.removed(address: address)]
        } else {
            return
        }
        
        hasChanges = true
        
        NotificationCenter.default.post(
            name: Notification.Name.AdamantAddressBookService.addressBookUpdated,
            object: self,
            userInfo: [AdamantUserInfoKey.AddressBook.changes: changes]
        )
        
        await Task.sleep(interval: waitTime)
        await saveIfNeeded()
    }
    
    // MARK: - Updating
    
    func update() async -> AddressBookServiceResult? {
        guard !hasChanges else {
            return nil
        }
        
        do {
            let book = try await getAddressBook()
            
            guard self.addressBook != book else {
                return .success
            }
            
            var localBook = self.addressBook
            var changes = [AddressBookChange]()
            
            for (address, name) in book {
                if let localName = localBook[address] {
                    if localName != name {
                        localBook[address] = name
                        changes.append(AddressBookChange.updated(address: address, name: name))
                    }
                } else {
                    if let removedName = self.removedNames[address], removedName == name {
                        continue
                    }
                    
                    localBook[address] = name
                    changes.append(AddressBookChange.newName(address: address, name: name))
                }
            }
            
            self.addressBook = localBook
            
            NotificationCenter.default.post(
                name: Notification.Name.AdamantAddressBookService.addressBookUpdated,
                object: self,
                userInfo: [AdamantUserInfoKey.AddressBook.changes: changes]
            )
            
            return .success
        } catch {
            return nil
        }
    }
    
    // MARK: - Saving
    
    func saveIfNeeded() async {
        guard hasChanges else {
            return
        }
        
        // Background task
        savingBookTaskId = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.savingBookTaskId)
            self.savingBookTaskId = .invalid
        }
        
        guard let id = try? await saveAddressBook(addressBook) else {
            return
        }
        
        var done: Bool = false
        
        // Hold updates until transaction passed on backend
        
        while !done {
            await Task.sleep(interval: 3.0)
            
            if let _ = try? await apiService.getTransaction(id: id) {
                done = true
            }
        }
        
        if done {
            self.hasChanges = false
            self.removedNames.removeAll()
        }
        
        UIApplication.shared.endBackgroundTask(self.savingBookTaskId)
        self.savingBookTaskId = .invalid
    }
    
    private func saveAddressBook(_ book: [String: String]) async throws -> UInt64 {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            throw AddressBookServiceError.notLogged
        }
        
        guard loggedAccount.balance >= AdamantApiService.KvsFee else {
            throw AddressBookServiceError.notEnoughMoney
        }
        
        let address = loggedAccount.address
        
        // MARK: 1. Pack and ecode address book
        
        let packed = AdamantAddressBookService.packAddressBook(book: book)
        
        guard let encodeResult = adamantCore.encodeValue(
            packed,
            privateKey: keypair.privateKey
        ) else {
            throw AddressBookServiceError.internalError(message: "Processing error", error: nil)
        }
        
        let value = AdamantUtilities.JSONStringify(
            value: ["message": encodeResult.message,
                    "nonce": encodeResult.nonce] as AnyObject
        )
        
        // MARK: 2. Submit to KVS
        
        do {
            let id = try await apiService.store(
                key: addressBookKey,
                value: value,
                type: .keyValue,
                sender: address,
                keypair: keypair
            )
            
            return id
        } catch let error as ApiServiceError {
            throw AddressBookServiceError.apiServiceError(error: error)
        } catch {
            throw AddressBookServiceError.internalError(
                message: error.localizedDescription,
                error: error
            )
        }
    }
    
    // MARK: - Getting address book
    
    private func getAddressBook() async throws -> [String: String] {
        guard let loggedAccount = accountService.account,
              let keypair = accountService.keypair
        else {
            throw AddressBookServiceError.notLogged
        }
        
        let address = loggedAccount.address
        
        do {
            let rawValue = try await apiService.get(key: addressBookKey, sender: address)
            guard let value = rawValue,
                  let object = value.toDictionary(),
                  let message = object["message"] as? String,
                  let nonce = object["nonce"] as? String
            else {
                throw AddressBookServiceError.internalError(message: "Processing error", error: nil)
            }
            
            // MARK: Encoding
            
            guard let result = adamantCore.decodeValue(
                rawMessage: message,
                rawNonce: nonce,
                privateKey: keypair.privateKey
            ),
                  let value = result.matches(for: "\\{.*\\}").first,
                  let object = value.toDictionary(),
                  let rawAddressBook = object["payload"] as? [String: Any]
            else {
                throw AddressBookServiceError.internalError(message: "Encoding error", error: nil)
            }
            
            let book = AdamantAddressBookService.processAddressBook(rawBook: rawAddressBook)
            
            return book
        } catch let error as ApiServiceError {
            throw AddressBookServiceError.apiServiceError(error: error)
        } catch {
            throw AddressBookServiceError.internalError(
                message: error.localizedDescription,
                error: error
            )
        }
    }
}

// MARK: - Tools

extension AdamantAddressBookService {
    private static func processAddressBook(rawBook: [String:Any]) -> [String:String] {
        var processedBook = [String:String]()
        for key in rawBook.keys {
            if let value = rawBook[key] as? [String:Any], let displayName = value["displayName"] as? String {
                if !displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                    processedBook[key] = displayName
                }
            }
        }
        return processedBook
    }
    
    private static func packAddressBook(book: [String:String]) -> [String:Any] {
        var processedBook = [String:Any]()
        for key in book.keys {
            if let value = book[key] {
                processedBook[key] = ["displayName": value]
            }
        }
        return processedBook
    }
}
