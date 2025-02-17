//
//  KlyWalletService+Send.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
@preconcurrency import LiskKit
import CommonKit

extension KlyWalletService: WalletServiceTwoStepSend {
    typealias T = TransactionEntity
    
    // MARK: Create & Send
    func createTransaction(
        recipient: String,
        amount: Decimal,
        fee: Decimal,
        comment: String?
    ) async throws -> TransactionEntity {
        // MARK: 1. Prepare
        guard let wallet = klyWallet else {
            throw WalletServiceError.notLogged
        }
        
        guard let binaryAddress = LiskKit.Crypto.getBinaryAddressFromBase32(recipient) else {
            throw WalletServiceError.accountNotFound
        }
        
        let keys = wallet.keyPair
        
        // MARK: 2. Create local transaction
        
        let transaction = klyTransactionFactory.createTx(
            amount: amount,
            fee: fee,
            nonce: wallet.nonce,
            senderPublicKey: wallet.keyPair.publicKeyString,
            recipientAddressBinary: binaryAddress,
            comment: comment ?? .empty
        )
        
        let signedTransaction = transaction.sign(with: keys, for: Constants.chainID)
        return signedTransaction
    }
    
    func sendTransaction(_ transaction: TransactionEntity) async throws {
        _ = try await klyNodeApiService.requestTransactionsApi { api in
            try await api.submit(transaction: transaction)
        }.get()
    }
}

extension LocalTransaction: RawTransaction {
    var txHash: String? {
        return id
    }
}

extension TransactionEntity: RawTransaction {
    var txHash: String? {
        return id
    }
}
