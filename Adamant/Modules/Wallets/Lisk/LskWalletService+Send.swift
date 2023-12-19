//
//  LskWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 29/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import LiskKit
import CommonKit

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

extension LskWalletService: WalletServiceTwoStepSend {
    typealias T = TransactionEntity
    
    // MARK: Create & Send
    func createTransaction(
        recipient: String,
        amount: Decimal,
        fee: Decimal
    ) async throws -> TransactionEntity {
        // MARK: 1. Prepare
        guard let wallet = lskWallet, let binaryAddress = LiskKit.Crypto.getBinaryAddressFromBase32(recipient) else {
            throw WalletServiceError.notLogged
        }
        
        let keys = wallet.keyPair
        
        // MARK: 2. Create local transaction
        
        let transaction = TransactionEntity().createTx(
            amount: amount,
            fee: fee,
            nonce: wallet.nonce,
            senderPublicKey: wallet.keyPair.publicKeyString,
            recipientAddressBinary: binaryAddress
        )
        
        let signedTransaction = transaction.sign(with: keys, for: Constants.chainID)
        return signedTransaction
    }
    
    func sendTransaction(_ transaction: TransactionEntity) async throws {
        _ = try await lskNodeApiService.requestTransactionsApi { api, completion in
            Task {
                do {
                    let id = try await api.submit(transaction: transaction)
                    completion(.success(response: id))
                } catch let error as APIError {
                    completion(.error(response: error))
                } catch {
                    completion(.error(response: APIError.unknown(code: nil)))
                }
            }
        }.get()
    }
}
