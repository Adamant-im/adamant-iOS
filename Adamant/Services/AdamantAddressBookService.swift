//
//  AdamantAddressBookService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 24/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Clibsodium

class AdamantAddressBookService: AddressBookService {
    let addressBookKey = "contact_list"
    let waitTime: TimeInterval = 20.0 // in sec
    
    // MARK: - Dependencies
    
    private let apiService: ApiService
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    private let dialogService: DialogService
    
    // MARK: - Properties
    
    var addressBook: [String:String] = [String:String]()
    
    private(set) var hasChanges = false
    private var timer: Timer?
    
    private var removedNames = [String:String]()
    
    private var isChangingSemaphore = DispatchSemaphore(value: 1)
    private var isSavingSemaphore = DispatchSemaphore(value: 1)
    
    private var savingBookTaskId = UIBackgroundTaskIdentifier.invalid
    private var savingBookOnLogoutTaskId = UIBackgroundTaskIdentifier.invalid
    
    // MARK: - Lifecycle
    init(
        apiService: ApiService,
        adamantCore: AdamantCore,
        accountService: AccountService,
        dialogService: DialogService
    ) {
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.accountService = accountService
        self.dialogService = dialogService
        
        // Update on login
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
            self?.update(nil)
        }
        
        // Save on logout
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userWillLogOut, object: nil, queue: nil) { [unowned self] _ in
            self.isSavingSemaphore.wait()
            
            defer {
                self.isSavingSemaphore.signal()
            }
            
            guard self.hasChanges else {
                return
            }
            
            self.savingBookOnLogoutTaskId = UIApplication.shared.beginBackgroundTask { [unowned self] in
                UIApplication.shared.endBackgroundTask(self.savingBookOnLogoutTaskId)
                self.savingBookOnLogoutTaskId = .invalid
            }
            
            self.saveAddressBook(self.addressBook) { _ in
                UIApplication.shared.endBackgroundTask(self.savingBookOnLogoutTaskId)
                self.savingBookOnLogoutTaskId = .invalid
            }
        }
        
        // Clean on logout
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { _ in
            self.isChangingSemaphore.wait()
            
            defer {
                self.isChangingSemaphore.signal()
            }
            
            self.hasChanges = false
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
            
            self.addressBook.removeAll()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setting
    
    func set(name: String, for address: String) {
        isChangingSemaphore.wait()
        
        defer {
            isChangingSemaphore.signal()
        }
        
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
        
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: waitTime, repeats: false) { [weak self] _ in
            self?.saveIfNeeded()
        }
        
        NotificationCenter.default.post(name: Notification.Name.AdamantAddressBookService.addressBookUpdated,
                                        object: self,
                                        userInfo: [AdamantUserInfoKey.AddressBook.changes: changes])
    }
    
    // MARK: - Updating
    
    func update() {
        update(nil)
    }
    
    func update(_ completion: ((AddressBookServiceResult) -> Void)?) {
        // Check if book has changes. Skip update until changes is saved
        isChangingSemaphore.wait()
        guard !hasChanges else {
            isChangingSemaphore.signal()
            return
        }
        isChangingSemaphore.signal()
        
        isSavingSemaphore.wait()
        
        getAddressBook { result in
            defer {
                self.isSavingSemaphore.signal()
            }
            
            switch result {
            case .success(let book):
                if self.addressBook != book {
                    self.isChangingSemaphore.wait()
                    
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
                    
                    self.isChangingSemaphore.signal()
                    
                    NotificationCenter.default.post(name: Notification.Name.AdamantAddressBookService.addressBookUpdated,
                                                    object: self,
                                                    userInfo: [AdamantUserInfoKey.AddressBook.changes: changes])
                }
                
                completion?(.success)
                
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    // MARK: - Saving
    
    func saveIfNeeded() {
        isChangingSemaphore.wait()
        
        guard hasChanges else {
            isChangingSemaphore.signal()
            return
        }
        
        isChangingSemaphore.signal()
        
        isSavingSemaphore.wait()
        
        // Check again
        isChangingSemaphore.wait()
        guard hasChanges else {
            isSavingSemaphore.signal()
            isChangingSemaphore.signal()
            return
        }
        isChangingSemaphore.signal()
        
        // Background task
        savingBookTaskId = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.savingBookTaskId)
            self.savingBookTaskId = .invalid
        }
        
        saveAddressBook(addressBook) { result in
            defer {
                self.isSavingSemaphore.signal()
                
                UIApplication.shared.endBackgroundTask(self.savingBookTaskId)
                self.savingBookTaskId = .invalid
            }
            
            switch result {
            case .success(let id):
                var done: Bool = false
                let group = DispatchGroup()
                
                // Hold updates until transaction passed on backend
                while !done {
                    Thread.sleep(forTimeInterval: 3.0)
                    
                    group.enter()
                    
                    self.apiService.getTransaction(id: id) { result in
                        defer { group.leave() }
                        
                        switch result {
                        case .success: done = true
                        default: break
                        }
                    }
                    
                    group.wait()
                }
                
                if done {
                    self.isChangingSemaphore.wait()
                    self.hasChanges = false
                    self.isChangingSemaphore.signal()
                    
                    self.removedNames.removeAll()
                }
                
            case .failure(let error):
                print("\(error.localizedDescription)")
            }
        }
    }
    
    private func saveAddressBook(_ book: [String: String], completion: @escaping (AddressBookServiceResultId) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        guard loggedAccount.balance >= AdamantApiService.KvsFee else {
            completion(.failure(.notEnoughMoney))
            return
        }
        
        let address = loggedAccount.address
        
        // MARK: 1. Pack and ecode address book
        let packed = AdamantAddressBookService.packAddressBook(book: book)
        if let encodeResult = adamantCore.encodeValue(packed, privateKey: keypair.privateKey) {
            let value = AdamantUtilities.JSONStringify(value: ["message": encodeResult.message,
                                              "nonce": encodeResult.nonce] as AnyObject)
            
            // MARK: 2. Submit to KVS
            apiService.store(key: addressBookKey, value: value, type: .keyValue, sender: address, keypair: keypair) { (result) in
                switch result {
                case .success(let id):
                    completion(.success(id: id))
                    
                case .failure(let error):
                    completion(.failure(.apiServiceError(error: error)))
                }
            }
        }
    }
    
    // MARK: - Getting address book
    private enum GetAddressBookResult {
        case success([String:String])
        case failure(AddressBookServiceError)
    }
    
    private func getAddressBook(completion: @escaping (GetAddressBookResult) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        let address = loggedAccount.address
        
        apiService.get(key: addressBookKey, sender: address) { [weak self] (result) in
            switch result {
            case .success(let rawValue):
                guard let value = rawValue, let object = value.toDictionary() else {
                    completion(.failure(.internalError(message: "Processing error", error: nil)))
                    return
                }
                
                guard let message = object["message"] as? String,
                    let nonce = object["nonce"] as? String else {
                    completion(.failure(.internalError(message: "Processing error", error: nil)))
                    return
                }
                
                // MARK: Encoding
                if let result = self?.adamantCore.decodeValue(rawMessage: message, rawNonce: nonce, privateKey: keypair.privateKey),
                    let value = result.matches(for: "\\{.*\\}").first,
                    let object = value.toDictionary(),
                    let rawAddressBook = object["payload"] as? [String:Any] {
                    let book = AdamantAddressBookService.processAddressBook(rawBook: rawAddressBook)
                    completion(.success(book))
                } else {
                    completion(.failure(.internalError(message: "Encoding error", error: nil)))
                }
                
            case .failure(let error):
                completion(.failure(.apiServiceError(error: error)))
            }
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

private enum AddressBookServiceResultId {
    case success(id: UInt64)
    case failure(AddressBookServiceError)
}
