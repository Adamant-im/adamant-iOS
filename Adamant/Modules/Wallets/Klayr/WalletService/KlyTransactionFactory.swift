//
//  KlyTransactionFactory.swift
//  Adamant
//
//  Created by Christian Benua on 21.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import LiskKit

final class KlyTransactionFactory: KlyTransactionFactoryProtocol {
    func createTx(
        amount: Decimal,
        fee: Decimal,
        nonce: UInt64,
        senderPublicKey: String,
        recipientAddressBinary: String,
        comment: String
    ) -> TransactionEntity {
        TransactionEntity().createTx(
            amount: amount,
            fee: fee,
            nonce: nonce,
            senderPublicKey: senderPublicKey,
            recipientAddressBinary: recipientAddressBinary,
            comment: comment
        )
    }
}
