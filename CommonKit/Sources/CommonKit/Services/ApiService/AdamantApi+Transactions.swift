//
//  AdamantApi+Transactions.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public extension ApiCommands {
    static let Transactions = (
        root: "/api/transactions",
        getTransaction: "/api/transactions/get",
        normalizeTransaction: "/api/transactions/normalize",
        processTransaction: "/api/transactions/process"
    )
}

extension AdamantApiService {
    public func sendTransaction(
        path: String,
        transaction: UnregisteredTransaction
    ) async -> ApiServiceResult<UInt64> {
        let response: ApiServiceResult<TransactionIdResponse> = await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: path,
                method: .post,
                parameters: ["transaction": transaction],
                encoding: .json
            )
        }
        
        return response.flatMap { $0.resolved() }
    }
    
    public func sendDelegateVoteTransaction(
        path: String,
        transaction: UnregisteredTransaction
    ) async -> ApiServiceResult<Bool> {
        let response: ApiServiceResult<ServerResponse> = await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: path,
                method: .post,
                parameters: transaction,
                encoding: .json
            )
        }
        
        return response.flatMap {
            guard let error = $0.error else { return .success($0.success) }
            return .failure(.serverError(error: error))
        }
    }
    
    public func getTransaction(id: UInt64) async -> ApiServiceResult<Transaction> {
        await getTransaction(id: id, withAsset: false)
    }
    
    public func getTransaction(id: UInt64, withAsset: Bool) async -> ApiServiceResult<Transaction> {
        let response: ApiServiceResult<ServerModelResponse<Transaction>>
        response = await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Transactions.getTransaction,
                method: .get,
                parameters: [
                    "id": String(id),
                    "returnAsset": withAsset ? "1" : "0"
                ],
                encoding: .url
            )
        }
        
        return response.flatMap { $0.resolved() }
    }
    
    public func getTransactions(
        forAccount account: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?,
        waitsForConnectivity: Bool
    ) async -> ApiServiceResult<[Transaction]> {
        await getTransactions(
            forAccount: account,
            type: type,
            fromHeight: fromHeight,
            offset: offset,
            limit: limit,
            orderByTime: false,
            waitsForConnectivity: waitsForConnectivity
        )
    }
    
    public func getTransactions(
        forAccount account: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?,
        orderByTime: Bool?,
        waitsForConnectivity: Bool
    ) async -> ApiServiceResult<[Transaction]> {
        var queryItems = [URLQueryItem(name: "inId", value: account)]
        
        if type == .send {
            // transfers can be of type 0 and 8 so we can filter by min amount
            queryItems.append(URLQueryItem(name: "and:minAmount", value: "1"))
        } else {
            queryItems.append(URLQueryItem(name: "and:type", value: String(type.rawValue)))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        if let fromHeight = fromHeight, fromHeight > 0 {
            queryItems.append(URLQueryItem(name: "and:fromHeight", value: String(fromHeight)))
        }
        
        if let orderByTime = orderByTime, orderByTime {
            queryItems.append(URLQueryItem(name: "orderBy", value: "timestamp:desc"))
        }
        
        let response: ApiServiceResult<ServerCollectionResponse<Transaction>>
        response = await request(waitsForConnectivity: waitsForConnectivity) {
            [queryItems] core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Transactions.root,
                method: .get,
                parameters: core.emptyParameters,
                encoding: .forceQueryItems(queryItems)
            )
        }
        
        return response.flatMap { $0.resolved() }
    }
}
