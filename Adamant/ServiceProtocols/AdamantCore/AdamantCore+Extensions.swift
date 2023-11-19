//
//  AdamantCore+Extensions.swift
//  Adamant
//
//  Created by Andrey Golubenko on 25.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension AdamantCore {
    func makeSignedTransaction(
        transaction: SignableTransaction,
        senderId: String,
        keypair: Keypair
    ) -> UnregisteredTransaction? {
        guard let signature = sign(transaction: transaction, senderId: senderId, keypair: keypair) else {
            return nil
        }
        
        return .init(
            type: transaction.type,
            timestamp: transaction.timestamp,
            senderPublicKey: transaction.senderPublicKey,
            senderId: senderId,
            recipientId: transaction.recipientId,
            amount: transaction.amount,
            signature: signature,
            asset: transaction.asset
        )
    }
    
    func makeSendMessageTransaction(
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        message: String,
        type: ChatType,
        nonce: String,
        amount: Decimal?
    ) throws -> UnregisteredTransaction {
        let normalizedTransaction = NormalizedTransaction(
            type: .chatMessage,
            amount: amount ?? .zero,
            senderPublicKey: keypair.publicKey,
            requesterPublicKey: nil,
            date: Date(),
            recipientId: recipientId,
            asset: TransactionAsset(
                chat: ChatAsset(message: message, ownMessage: nonce, type: type),
                state: nil,
                votes: nil
            )
        )
        
        guard let transaction = makeSignedTransaction(
            transaction: normalizedTransaction,
            senderId: senderId,
            keypair: keypair
        ) else {
            throw InternalAPIError.signTransactionFailed
        }
        
        return transaction
    }
}
