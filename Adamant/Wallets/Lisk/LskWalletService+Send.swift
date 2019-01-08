//
//  LskWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 29/11/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Lisk
import PromiseKit

extension LocalTransaction: RawTransaction {
    var txHash: String? {
        return id
    }
}

extension LskWalletService: WalletServiceTwoStepSend {
    typealias T = LocalTransaction
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Lisk.transfer) as? LskTransferViewController else {
            fatalError("Can't get LskTransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<LocalTransaction>) -> Void) {
        // MARK: 1. Prepare
        guard let wallet = lskWallet else {
            completion(.failure(error: .notLogged))
            return
        }
        
        let keys = wallet.keyPair
        
        // MARK: Go background
        defaultDispatchQueue.async {
            // MARK: 2. Create local transaction
            do {
                let transaction = LocalTransaction(.transfer, lsk: amount.doubleValue, recipientId: recipient)
                let signedTransaction = try transaction.signed(keyPair: keys)
                
                completion(.success(result: signedTransaction))
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "Transaction sign error", error: error)))
            }
        }
    }
    
    func sendTransaction(_ transaction: LocalTransaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
        defaultDispatchQueue.async {
            self.transactionApi.submit(signedTransaction: transaction) { response in
                switch response {
                case .success(let result):
                    print(result.data.hashValue)
                    print(result.data.message)
                    
                    completion(.success(result: transaction.id ?? ""))
                case .error(let error):
                    print("ERROR: " + error.message)
                    completion(.failure(error: .internalError(message: error.message, error: nil)))
                }
            }
        }
    }
}
