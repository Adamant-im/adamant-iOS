//
//  AdamantAddressBookService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 24/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import libsodium

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
    
    private func processAddressBook(rawBook: [String:Any]) -> [String:String] {
        var processedBook = [String:String]()
        for key in rawBook.keys {
            if let value = rawBook[key] as? [String:Any], let displayName = value["displayName"] as? String {
                processedBook[key] = displayName
            }
        }
        return processedBook
    }
}
