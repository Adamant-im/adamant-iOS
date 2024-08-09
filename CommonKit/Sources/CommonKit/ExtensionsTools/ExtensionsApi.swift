//
//  ExtensionsApi.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public final class ExtensionsApi {
    // MARK: Properties
    private let addressBookKey = "contact_list"
    private let apiService: ApiService
    
    // MARK: Cotr
    public init(apiService: ApiService) {
        self.apiService = apiService
    }
    
    // MARK: - API
    
    // MARK: Transactions
    public func getTransaction(by id: UInt64) -> Transaction? {
        syncRequest { [apiService] in
            try? await apiService.getTransaction(id: id).get()
        }
    }
    
    // MARK: Address book
    
    public func getAddressBook(
        for address: String,
        core: NativeAdamantCore,
        keypair: Keypair
    ) -> [String:ContactDescription]? {
        let addressBookString = syncRequest { [apiService, addressBookKey] in
            try? await apiService.get(key: addressBookKey, sender: address).get()
        }
        
        // Working with transaction
        
        guard
            let object = addressBookString?.toDictionary(),
            let message = object["message"] as? String,
            let nonce = object["nonce"] as? String
        else {
            return nil
        }
        
        // Decoding
        guard let decodedMessage = core.decodeValue(rawMessage: message, rawNonce: nonce, privateKey: keypair.privateKey),
            let rawJson = decodedMessage.matches(for: "\\{.*\\}").first,
            let contacts = rawJson.toDictionary()?["payload"] as? [String:Any] else {
                return nil
        }
        
        var result = [String:ContactDescription]()
        let decoder = JSONDecoder()
        
        for (key, value) in contacts {
            guard let data = try? JSONSerialization.data(withJSONObject: value, options: []),
                let description = try? decoder.decode(ContactDescription.self, from: data) else {
                continue
            }
            
            result[key] = description
        }
        
        if result.count > 0 {
            return result
        } else {
            return nil
        }
    }
    
    private func syncRequest<T: Sendable>(
        _ request: @Sendable @escaping () async -> T?
    ) -> T? {
        let result = Atomic<T?>(wrappedValue: nil)
        let semaphore = DispatchSemaphore(value: .zero)
        
        Task.detached {
            result.wrappedValue = await request()
            semaphore.signal()
        }
        
        semaphore.wait()
        return result.wrappedValue
    }
}
