//
//  AdamantApi+Chats.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

public extension ApiCommands {
    static let Chats = (
        root: "/api/chats",
        get: "/api/chats/get",
        normalizeTransaction: "/api/chats/normalize",
        processTransaction: "/api/chats/process",
        getChatRooms: "/api/chatrooms"
    )
}

extension AdamantApiService {
    public func getMessageTransactions(
        address: String,
        height: Int64?,
        offset: Int?,
        waitsForConnectivity: Bool
    ) async -> ApiServiceResult<[Transaction]> {
        var parameters = [
            "isIn": address,
            "orderBy": "timestamp:desc"
        ]
        
        if let height = height, height > .zero {
            parameters["fromHeight"] = String(height)
        }
        
        if let offset = offset {
            parameters["offset"] = String(offset)
        }
        
        let response: ApiServiceResult<ServerCollectionResponse<Transaction>>
        response = await request(waitsForConnectivity: waitsForConnectivity) {
            [parameters] service, origin in
            await service.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Chats.get,
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }
        
        return response.flatMap { $0.resolved() }
    }
    
    public func sendMessageTransaction(
        transaction: UnregisteredTransaction,
        timeout: TimeInterval? = nil
    ) async -> ApiServiceResult<UInt64> {
        await sendTransaction(
            path: ApiCommands.Chats.processTransaction,
            transaction: transaction,
            timeout: timeout
        )
    }
    
    public func getChatRooms(
        address: String,
        offset: Int?,
        waitsForConnectivity: Bool
    ) async -> ApiServiceResult<ChatRooms> {
        var parameters = ["limit": "20"]
        
        if let offset = offset {
            parameters["offset"] = String(offset)
        }
        
        return await request(waitsForConnectivity: waitsForConnectivity) {
            [parameters] service, origin in
            await service.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Chats.getChatRooms + "/\(address)",
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }
    }
    
    public func getChatMessages(
        address: String,
        addressRecipient: String,
        offset: Int?,
        limit: Int?
    ) async -> ApiServiceResult<ChatRooms> {
        var parameters: [String: String] = [:]
        
        if let offset = offset {
            parameters["offset"] = String(offset)
        }
        
        if let limit = limit {
            parameters["limit"] = String(limit)
        }
        
        return await request { [parameters] service, origin in
            await service.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Chats.getChatRooms + "/\(address)/\(addressRecipient)",
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }
    }
}
