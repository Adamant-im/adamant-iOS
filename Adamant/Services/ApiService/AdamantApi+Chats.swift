//
//  AdamantApi+Chats.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

extension AdamantApiService.ApiCommands {
    static let Chats = (
        root: "/api/chats",
        get: "/api/chats/get",
        normalizeTransaction: "/api/chats/normalize",
        processTransaction: "/api/chats/process"
    )
}

extension AdamantApiService {
    func getMessageTransactions(address: String, height: Int64?, offset: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void) {
        // MARK: 1. Prepare params
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "isIn", value: address),
                                          URLQueryItem(name: "orderBy", value: "timestamp:desc")]
        if let height = height, height > 0 { queryItems.append(URLQueryItem(name: "fromHeight", value: String(height))) }
        if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
        
        // MARK: 2. Build endpoint
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Chats.get, queryItems: queryItems)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        // MARK: 3. Send
        sendRequest(url: endpoint) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Transaction>>) in
            switch serverResponse {
            case .success(let response):
                if let collection = response.collection {
                    completion(.success(collection))
                } else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func sendMessage(senderId: String, recipientId: String, keypair: Keypair, message: String, type: ChatType, nonce: String, amount: Decimal?, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {
        
        // MARK: 0. Prepare
        let date: Date
        if let delta = nodeTimeDelta {
            date = Date().addingTimeInterval(-delta)
        } else {
            date = Date()
        }
        
        let processEndpoin: URL
        
        do {
            processEndpoin = try buildUrl(path: ApiCommands.Chats.processTransaction)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        // MARK: 1. Create transaction and sign it
        let normalizedTransaction = NormalizedTransaction(type: .chatMessage,
                                                amount: amount ?? 0,
                                                senderPublicKey: keypair.publicKey,
                                                requesterPublicKey: nil,
                                                date: date,
                                                recipientId: recipientId,
                                                asset: TransactionAsset(chat: ChatAsset(message: message, ownMessage: nonce, type: type),
                                                                        state: nil,
                                                                        votes: nil))
        
        guard let signature = adamantCore.sign(transaction: normalizedTransaction, senderId: senderId, keypair: keypair) else {
            completion(.failure(InternalError.signTransactionFailed.apiServiceErrorWith(error: nil)))
            return
        }
        
        // MARK: 2. Build request
        let transaction: [String: Any] = [
            "type": normalizedTransaction.type.rawValue,
            "amount": (normalizedTransaction.amount.shiftedToAdamant() as NSDecimalNumber).uint64Value,
            "senderPublicKey": normalizedTransaction.senderPublicKey,
            "requesterPublicKey": normalizedTransaction.requesterPublicKey ?? NSNull(),
            "timestamp": normalizedTransaction.timestamp,
            "recipientId": normalizedTransaction.recipientId ?? NSNull(),
            "senderId": senderId,
            "signature": signature,
            "asset": [
                "chat": [
                    "message": message,
                    "own_message": nonce,
                    "type": type.rawValue
                ]
            ]
        ]
        
        let params: [String: Any] = [
            "transaction": transaction
        ]
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 3. Send request
        
        self.sendRequest(url: processEndpoin, method: .post, parameters: params, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<TransactionIdResponse>) in
            switch serverResponse {
            case .success(let response):
                if let id = response.transactionId {
                    completion(.success(id))
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
