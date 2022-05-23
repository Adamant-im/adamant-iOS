//
//  AdamantApi+States.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

extension AdamantApiService.ApiCommands {
    static let States = (
        root: "/api/states",
        get: "/api/states/get",
        store: "/api/states/store"
    )
}

extension AdamantApiService {
    
    static let KvsFee: Decimal = 0.001
    
    func store(key: String, value: String, type: StateType, sender: String, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {
        self.sendingMsgTaskId = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.sendingMsgTaskId)
            self.sendingMsgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        // MARK: 1. Create and sign transaction
        let asset = TransactionAsset(state: StateAsset(key: key, value: value, type: .keyValue))
        let transaction = NormalizedTransaction(type: .state,
                                                amount: 0,
                                                senderPublicKey: keypair.publicKey,
                                                requesterPublicKey: nil,
                                                date: Date(),
                                                recipientId: nil,
                                                asset: asset)
        guard let signature = adamantCore.sign(transaction: transaction, senderId: sender, keypair: keypair) else {
            completion(.failure(.internalError(message: "Failed to sign transaction", error: nil)))
            return
        }
        
        let params: [String: Any] = [
            "transaction": [
                "type": transaction.type.rawValue,
                "amount": transaction.amount,
                "senderPublicKey": transaction.senderPublicKey,
                "senderId": sender,
                "timestamp": transaction.timestamp,
                "signature": signature,
                "recipientId": NSNull(),
                "asset": [
                    "state": [
                        "key": key,
                        "value": value,
                        "type": type.rawValue
                    ]
                ]
            ]
        ]
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Send
        sendRequest(
            path: ApiCommands.States.store,
            method: .post,
            parameters: params,
            encoding: .json,
            headers: headers
        ) { (serverResponse: ApiServiceResult<TransactionIdResponse>) in
            switch serverResponse {
            case .success(let response):
                if let id = response.transactionId {
                    completion(.success(id))
                } else {
                    completion(ApiServiceResult.success(0))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
            
            do {
                UIApplication.shared.endBackgroundTask(self.sendingMsgTaskId)
                self.sendingMsgTaskId = UIBackgroundTaskIdentifier.invalid
            }
        }
    }
    
    func get(key: String, sender: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        // MARK: 1. Prepare
        let queryItems = [URLQueryItem(name: "senderId", value: sender),
                          URLQueryItem(name: "orderBy", value: "timestamp:desc"),
                          URLQueryItem(name: "key", value: key)]
        
        // MARK: 2. Send
        sendRequest(
            path: ApiCommands.States.get,
            queryItems: queryItems
        ) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Transaction>>) in
            switch serverResponse {
            case .success(let response):
                if let collection = response.collection {
                    if collection.count > 0, let value = collection.first?.asset.state?.value {
                        completion(.success(value))
                    } else {
                        completion(.success(nil))
                    }
                } else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
