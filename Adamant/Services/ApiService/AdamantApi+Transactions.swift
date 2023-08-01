//
//  AdamantApi+Transactions.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension AdamantApiService.ApiCommands {
    static let Transactions = (
        root: "/api/transactions",
        getTransaction: "/api/transactions/get",
        normalizeTransaction: "/api/transactions/normalize",
        processTransaction: "/api/transactions/process"
    )
}

extension AdamantApiService {
    func sendTransaction(
        path: String,
        transaction: UnregisteredTransaction,
        completion: @escaping (ApiServiceResult<TransactionIdResponse>) -> Void
    ) {
        sendRequest(
            path: path,
            method: .post,
            body: ["transaction": transaction],
            completion: completion
        )
    }
    
    func sendDelegateVoteTransaction(
        path: String,
        transaction: UnregisteredTransaction,
        completion: @escaping (ApiServiceResult<TransactionIdResponse>) -> Void
    ) {
        sendRequest(
            path: path,
            method: .post,
            body: transaction,
            completion: completion
        )
    }
    
    func getTransaction(id: UInt64, completion: @escaping (ApiServiceResult<Transaction>) -> Void) {
        sendRequest(
            path: ApiCommands.Transactions.getTransaction,
            queryItems: [URLQueryItem(name: "id", value: String(id))]
        ) { (serverResponse: ApiServiceResult<ServerModelResponse<Transaction>>) in
            switch serverResponse {
            case .success(let response):
                if let model = response.model {
                    completion(.success(model))
                } else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func getTransaction(id: UInt64) async throws -> Transaction {
        try await getTransaction(id: id, withAsset: false)
    }
    
    func getTransaction(id: UInt64, withAsset: Bool) async throws -> Transaction {
        var queryItems = [
            URLQueryItem(name: "id", value: String(id)),
            URLQueryItem(name: "returnAsset", value: withAsset ? "1" : "0")
        ]
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Transaction, Error>) in
            sendRequest(
                path: ApiCommands.Transactions.getTransaction,
                queryItems: queryItems
            ) { (serverResponse: ApiServiceResult<ServerModelResponse<Transaction>>) in
                switch serverResponse {
                case .success(let response):
                    if let model = response.model {
                        continuation.resume(returning: model)
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
    
    func getTransactions(
        forAccount account: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?
    ) async throws -> [Transaction] {
        try await getTransactions(
            forAccount: account,
            type: type,
            fromHeight: fromHeight,
            offset: offset,
            limit: limit,
            orderByTime: false
        )
    }
    
    func getTransactions(
        forAccount account: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?,
        orderByTime: Bool?
    ) async throws -> [Transaction] {
        
        var queryItems = [URLQueryItem(name: "inId", value: account)]
        
        if type == .send {
            // transfers can be of type 0 and 8 so we can filter by min amount
            queryItems.append(URLQueryItem(name: "and:minAmount", value: "1"))
        } else {
            queryItems.append(URLQueryItem(name: "and:type", value: String(type.rawValue)))
        }
        
        if let limit = limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
        
        if let offset = offset { queryItems.append(URLQueryItem(name: "offset", value: String(offset))) }
        
        if let fromHeight = fromHeight, fromHeight > 0 {
            queryItems.append(URLQueryItem(name: "and:fromHeight", value: String(fromHeight)))
        }
        
        if let orderByTime = orderByTime, orderByTime {
            queryItems.append(URLQueryItem(name: "orderBy", value: "timestamp:desc"))
        }
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<[Transaction], Error>) in
            sendRequest(
                path: ApiCommands.Transactions.root,
                queryItems: queryItems
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
}
