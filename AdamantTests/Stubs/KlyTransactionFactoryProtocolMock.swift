//
//  KlyTransactionFactoryProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 21.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import Foundation
import LiskKit

final class KlyTransactionFactoryProtocolMock: KlyTransactionFactoryProtocol {
    
    var invokedCreateTx: Bool = false
    var invokedCreateTxCount: Int = 0
    var invokedCreateTxParameters: (amount: Decimal, fee: Decimal, nonce: UInt64, senderPublicKey: String, recipientAddressBinary: String, comment: String)?
    
    func createTx(
        amount: Decimal,
        fee: Decimal,
        nonce: UInt64,
        senderPublicKey: String,
        recipientAddressBinary: String,
        comment: String
    ) -> TransactionEntity {
        invokedCreateTx = true
        invokedCreateTxCount += 1
        invokedCreateTxParameters = (amount, fee, nonce, senderPublicKey, recipientAddressBinary, comment)
        
        return TransactionEntity().createTx(
            amount: amount,
            fee: fee,
            nonce: nonce,
            senderPublicKey: senderPublicKey,
            recipientAddressBinary: recipientAddressBinary,
            comment: comment
        )
    }
}
