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
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Lisk.transfer) as? LskTransferViewController else {
            fatalError("Can't get LskTransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal) async throws -> TransactionEntity {
        // MARK: 1. Prepare
        guard let wallet = lskWallet, let binaryAddress = LiskKit.Crypto.getBinaryAddressFromBase32(recipient) else {
            throw WalletServiceError.notLogged
        }
        
        let keys = wallet.keyPair
        
        // MARK: 2. Create local transaction
        
        let transaction = TransactionEntity(
            amount: amount,
            fee: self.transactionFee,
            nonce: wallet.nounce,
            senderPublicKey: wallet.keyPair.publicKeyString,
            recipientAddressBase32: recipient,
            recipientAddressBinary: binaryAddress
        )
        
        var signedTransaction = transaction.signed(with: keys, for: self.netHash)
        signedTransaction.id = signedTransaction.bytes().sha256().hexString()
        return signedTransaction
    }
    
    func sendTransaction(_ transaction: TransactionEntity) async throws {
        _ = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
            transactionApi.submit(signedTransaction: transaction.requestOptions) { response in
                switch response {
                case .success:
                    continuation.resume()
                case .error(let error):
                    continuation.resume(throwing: WalletServiceError.internalError(message: error.message, error: nil))
                }
            }
        }
    }
}
