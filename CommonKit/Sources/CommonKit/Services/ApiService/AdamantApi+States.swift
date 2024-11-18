//
//  AdamantApi+States.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

public extension ApiCommands {
    static let States = (
        root: "/api/states",
        get: "/api/states/get",
        store: "/api/states/store"
    )
}

extension AdamantApiService {
    public static let KvsFee: Decimal = 0.001
    
    public func store(
        key: String,
        value: String,
        type: StateType,
        sender: String,
        keypair: Keypair
    ) async -> ApiServiceResult<UInt64> {
        let transaction = NormalizedTransaction(
            type: .state,
            amount: .zero,
            senderPublicKey: keypair.publicKey,
            requesterPublicKey: nil,
            date: .now,
            recipientId: nil,
            asset: TransactionAsset(state: StateAsset(key: key, value: value, type: .keyValue))
        )
        
        guard let transaction = adamantCore.makeSignedTransaction(
            transaction: transaction,
            senderId: sender,
            keypair: keypair
        ) else {
            return .failure(.internalError(error: InternalAPIError.signTransactionFailed))
        }
        
        // MARK: Send
        
        return await sendTransaction(
            path: ApiCommands.States.store,
            transaction: transaction
        )
    }
    
    public func get(key: String, sender: String) async -> ApiServiceResult<String?> {
        // MARK: 1. Prepare
        let parameters = [
            "senderId": sender,
            "orderBy": "timestamp:desc",
            "key": key
        ]
        
        let response: ApiServiceResult<ServerCollectionResponse<Transaction>>
        response = await request { [parameters] core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.States.get,
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }
        
        return response
            .flatMap { $0.resolved() }
            .map { $0.first?.asset.state?.value }
    }
}
