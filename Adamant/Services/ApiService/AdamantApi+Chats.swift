//
//  AdamantApi+Chats.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit

extension AdamantApiService.ApiCommands {
    static let Chats = (
        root: "/api/chats",
        get: "/api/chats/get",
        normalizeTransaction: "/api/chats/normalize",
        processTransaction: "/api/chats/process",
        getChatRooms: "/api/chatrooms"
    )
}

extension AdamantApiService {
    func getMessageTransactions(address: String, height: Int64?, offset: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void) {
        // MARK: 1. Prepare params
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "isIn", value: address),
                                          URLQueryItem(name: "orderBy", value: "timestamp:desc")]
        if let height = height, height > 0 { queryItems.append(URLQueryItem(name: "fromHeight", value: String(height))) }
        if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
        
        // MARK: 2. Send
        sendRequest(
            path: ApiCommands.Chats.get,
            queryItems: queryItems
        ) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Transaction>>) in
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
    
    func getMessageTransactions(
        address: String,
        height: Int64?,
        offset: Int?
    ) async throws -> [Transaction] {
        // MARK: 1. Prepare params
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "isIn", value: address),
                                          URLQueryItem(name: "orderBy", value: "timestamp:desc")]
        if let height = height, height > 0 { queryItems.append(URLQueryItem(name: "fromHeight", value: String(height))) }
        if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
        
        // MARK: 2. Send
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<[Transaction], Error>) in
            sendRequest(
                path: ApiCommands.Chats.get,
                queryItems: queryItems,
                waitsForConnectivity: true
            ) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Transaction>>) in
                switch serverResponse {
                case .success(let response):
                    if let collection = response.collection {
                        continuation.resume(returning: collection)
                    } else {
                        let error = AdamantApiService.translateServerError(response.error)
                        continuation.resume(throwing: error)
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: ApiServiceError.networkError(error: error))
                }
            }
        }
    }
    
    @discardableResult
    func sendMessage(
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        message: String,
        type: ChatType,
        nonce: String,
        amount: Decimal?,
        completion: @escaping (ApiServiceResult<UInt64>) -> Void
    ) -> UnregisteredTransaction? {
        let normalizedTransaction = NormalizedTransaction(
            type: .chatMessage,
            amount: amount ?? .zero,
            senderPublicKey: keypair.publicKey,
            requesterPublicKey: nil,
            date: lastRequestTimeDelta.map { Date().addingTimeInterval(-$0) } ?? Date(),
            recipientId: recipientId,
            asset: TransactionAsset(
                chat: ChatAsset(message: message, ownMessage: nonce, type: type),
                state: nil,
                votes: nil
            )
        )
        
        guard let transaction = adamantCore.makeSignedTransaction(
            transaction: normalizedTransaction,
            senderId: senderId,
            keypair: keypair
        ) else {
            completion(.failure(InternalError.signTransactionFailed.apiServiceErrorWith(error: nil)))
            return nil
        }
        
        sendTransaction(path: ApiCommands.Chats.processTransaction, transaction: transaction) { response in
            switch response {
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
        
        return transaction
    }
    
    func createSendTransaction(
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        message: String,
        type: ChatType,
        nonce: String,
        amount: Decimal?
    ) -> UnregisteredTransaction? {
        let normalizedTransaction = NormalizedTransaction(
            type: .chatMessage,
            amount: amount ?? .zero,
            senderPublicKey: keypair.publicKey,
            requesterPublicKey: nil,
            date: lastRequestTimeDelta.map { Date().addingTimeInterval(-$0) } ?? Date(),
            recipientId: recipientId,
            asset: TransactionAsset(
                chat: ChatAsset(message: message, ownMessage: nonce, type: type),
                state: nil,
                votes: nil
            )
        )
        
        guard let transaction = adamantCore.makeSignedTransaction(
            transaction: normalizedTransaction,
            senderId: senderId,
            keypair: keypair
        ) else {
            return nil
        }
        
        return transaction
    }
    
    func sendTransaction(
        transaction: UnregisteredTransaction
    ) async throws -> UInt64 {
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<UInt64, Error>) in
            sendTransaction(path: ApiCommands.Chats.processTransaction, transaction: transaction) { response in
                switch response {
                case .success(let response):
                    if let id = response.transactionId {
                        continuation.resume(returning: id)
                    } else {
                        let error = AdamantApiService.translateServerError(response.error)
                        continuation.resume(throwing: error)
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: ApiServiceError.networkError(error: error))
                }
            }
        }
    }
    
    // new api
    
    func getChatRooms(address: String, offset: Int?, completion: @escaping (ApiServiceResult<ChatRooms>) -> Void) {
        // MARK: 1. Prepare params
        var queryItems: [URLQueryItem] = []
        if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
        queryItems.append(URLQueryItem(name: "limit", value: "20"))
        
        // MARK: 2. Send
        sendRequest(
            path: ApiCommands.Chats.getChatRooms + "/\(address)",
            queryItems: queryItems
        ) { (serverResponse: ApiServiceResult<ChatRooms>) in
            switch serverResponse {
            case .success(let response):
                completion(.success(response))
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func getChatRooms(
        address: String,
        offset: Int?
    ) async throws -> ChatRooms {
        // MARK: 1. Prepare params
        var queryItems: [URLQueryItem] = []
        if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
        queryItems.append(URLQueryItem(name: "limit", value: "20"))
        
        // MARK: 2. Send
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<ChatRooms, Error>) in
            sendRequest(
                path: ApiCommands.Chats.getChatRooms + "/\(address)",
                queryItems: queryItems,
                waitsForConnectivity: true
            ) { (serverResponse: ApiServiceResult<ChatRooms>) in
                switch serverResponse {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: ApiServiceError.networkError(error: error))
                }
            }
        }
    }
    
    func getChatMessages(
        address: String,
        addressRecipient: String,
        offset: Int?,
        limit: Int?
    ) async throws -> ChatRooms {
        // MARK: 1. Prepare params
        var queryItems: [URLQueryItem] = []
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        // MARK: 2. Send
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<ChatRooms, Error>) in
            sendRequest(
                path: ApiCommands.Chats.getChatRooms + "/\(address)/\(addressRecipient)",
                queryItems: queryItems,
                waitsForConnectivity: true
            ) { (serverResponse: ApiServiceResult<ChatRooms>) in
                switch serverResponse {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: ApiServiceError.networkError(error: error))
                }
            }
        }
    }
}
