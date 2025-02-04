//
//  KlyTransactionFactoryProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 21.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import LiskKit

protocol KlyTransactionFactoryProtocol: AnyObject {
    func createTx(
        amount: Decimal,
        fee: Decimal,
        nonce: UInt64,
        senderPublicKey: String,
        recipientAddressBinary: String,
        comment: String
    ) -> TransactionEntity
}
