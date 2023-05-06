//
//  AdamantCore+Extensions.swift
//  Adamant
//
//  Created by Andrey Golubenko on 25.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

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
}
