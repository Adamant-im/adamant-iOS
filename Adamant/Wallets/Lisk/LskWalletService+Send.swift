//
//  LskWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 29/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import LiskKit
import PromiseKit

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
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<TransactionEntity>) -> Void) {
        // MARK: 1. Prepare
        guard let wallet = lskWallet, let binaryAddress = LiskKit.Crypto.getBinaryAddressFromBase32(recipient) else {
            completion(.failure(error: .notLogged))
            return
        }
        
        let keys = wallet.keyPair
        
        // MARK: Go background
        defaultDispatchQueue.async {
            // MARK: 2. Create local transaction
            
            let transaction = TransactionEntity(amount: amount, fee: self.transactionFee, nonce: wallet.nounce, senderPublicKey: wallet.keyPair.publicKeyString, recipientAddress: binaryAddress)
            let signedTransaction = transaction.signed(with: keys, for: self.netHash)
            
            completion(.success(result: signedTransaction))
        }
    }
    
    func sendTransaction(_ transaction: TransactionEntity, completion: @escaping (WalletServiceResult<String>) -> Void) {
        defaultDispatchQueue.async {
            self.transactionApi.submit(signedTransaction: transaction.requestOptions) { response in
                switch response {
                case .success(let result):
                    print(result.data.hashValue)
                    print(result.data.transactionId)
                    completion(.success(result: result.data.transactionId))
                case .error(let error):
                    print("ERROR: " + error.message)
                    completion(.failure(error: .internalError(message: error.message, error: nil)))
                }
            }
        }
    }
}
