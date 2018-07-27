//
//  AdamantAddressBookService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 24/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import libsodium

// MARK: - Notifications
extension Notification.Name {
    struct AdamantAddressBookService {
        /// Raised when user rename accounts in chat
        static let updated = Notification.Name("adamant.addressBookService.updated")
        
        private init() {}
    }
}

class AdamantAddressBookService: AddressBookService {
    
    let addressBookKey = "contact_list"
    
    // MARK: Dependencies
    var apiService: ApiService!
    var adamantCore: AdamantCore!
    var accountService: AccountService!
    
    // MARK: Properties
    var addressBook: [String:String] = [String:String]()
    
    func getAddressBook(completion: @escaping (ApiServiceResult<[String:String]>) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        let address = loggedAccount.address
        
        apiService.get(key: addressBookKey, sender: address) { (result) in
            switch result {
            case .success(let rawValue):
                if let value = rawValue, let object = value.toDictionary() {
                    guard let message = object["message"] as? String, let nonce = object["nonce"] as? String else {
                        break
                    }
                    
                    if let result = self.adamantCore.decodeValue(rawMessage: message, rawNonce: nonce, privateKey: keypair.privateKey), let value = result.matches(for: "\\{.*\\}").first, let object = value.toDictionary(), let rawAddressBook = object["payload"] as? [String:Any] {
                        self.addressBook = self.processAddressBook(rawBook: rawAddressBook)
                        
                        completion(.success(self.addressBook))
                    } else {
                        completion(.failure(.internalError(message: "Processing error", error: nil)))
                    }
                } else {
                    completion(.failure(.internalError(message: "Processing error", error: nil)))
                }
                
            case .failure(let error):
                print(error)
                completion(.failure(.internalError(message: error.localizedDescription, error: error)))
            }
        }
    }
    
    func set(name: String, for address: String) {
        if name != "" { self.addressBook[address] = name }
        else { self.addressBook.removeValue(forKey: address) }
        
        NotificationCenter.default.post(name: Notification.Name.AdamantAddressBookService.updated, object: self)
        
        saveAddressBook { (result) in
            switch result {
            case .success(_): break
            case .failure(let error): print(error)
            }
        }
    }
    
    func saveAddressBook(completion: @escaping (ApiServiceResult<String>) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        let address = loggedAccount.address
        
        guard loggedAccount.balance >= AdamantApiService.KVSfee else {
            DispatchQueue.main.async {
                completion(.failure(.internalError(message: "ETH Wallet: Not enought ADM to save address to KVS", error: nil)))
            }
            return
        }
        
        // MARK: 1. Pack and ecode address book
        let packed = self.packAddressBook(book: self.addressBook)
        if let encodeResult = self.adamantCore.encodeValue(packed, privateKey: keypair.privateKey) {
            print(encodeResult)
            
            let value = JSONStringify(value: ["message": encodeResult.message,
                                      "nonce": encodeResult.nonce] as AnyObject)
            
            // MARK: 2. Submit to KVS
            self.apiService.store(key: addressBookKey, value: value, type: StateType.keyValue, sender: address, keypair: keypair) { (result) in
                switch result {
                case .success(let id):
                    print(id)
                    completion(.success("1"))
                    break
                case .failure(let error):
                    print(error)
                    completion(.failure(.internalError(message: error.localizedDescription, error: error)))
                }
            }
        }
    }
    
    private func processAddressBook(rawBook: [String:Any]) -> [String:String] {
        var processedBook = [String:String]()
        for key in rawBook.keys {
            if let value = rawBook[key] as? [String:Any], let displayName = value["displayName"] as? String {
                processedBook[key] = displayName
            }
        }
        return processedBook
    }
    
    private func packAddressBook(book: [String:String]) -> [String:Any] {
        var processedBook = [String:Any]()
        for key in book.keys {
            if let value = book[key] {
                processedBook[key] = ["displayName": value]
            }
        }
        return processedBook
    }
}
