//
//  AdamantApi+Transfers.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import CryptoSwift
import BigInt

extension AdamantApiService {
    func transferFunds(transaction: UnregisteredTransaction) async -> ApiServiceResult<UInt64> {
        return await sendTransaction(
            path: ApiCommands.Transactions.processTransaction,
            transaction: transaction
        )
    }

    func transferFunds(
        sender: String,
        recipient: String,
        amount: Decimal,
        keypair: Keypair
    ) async -> ApiServiceResult<UInt64> {
        let normalizedTransaction = NormalizedTransaction(
            type: .send,
            amount: amount,
            senderPublicKey: keypair.publicKey,
            requesterPublicKey: nil,
            date: .now,
            recipientId: recipient,
            asset: .init()
        )
        
        guard let transaction = adamantCore.makeSignedTransaction(
            transaction: normalizedTransaction,
            senderId: sender,
            keypair: keypair
        ) else {
            return .failure(.internalError(error: InternalAPIError.signTransactionFailed))
        }
        
        return await transferFunds(transaction: transaction)
    }
}
