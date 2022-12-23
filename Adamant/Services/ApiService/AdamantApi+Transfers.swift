//
//  AdamantApi+Transfers.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService {
    func transferFunds(sender: String, recipient: String, amount: Decimal, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {
        let normalizedTransaction = NormalizedTransaction(
            type: .send,
            amount: amount,
            senderPublicKey: keypair.publicKey,
            requesterPublicKey: nil,
            date: lastRequestTimeDelta.map { Date().addingTimeInterval(-$0) } ?? Date(),
            recipientId: recipient,
            asset: .init()
        )
        
        guard let transaction = adamantCore.makeSignedTransaction(
            transaction: normalizedTransaction,
            senderId: sender,
            keypair: keypair
        ) else {
            completion(.failure(InternalError.signTransactionFailed.apiServiceErrorWith(error: nil)))
            return
        }
        
        sendTransaction(
            path: ApiCommands.Transactions.processTransaction,
            transaction: transaction
        ) { response in
            switch response {
            case .success(let result):
                if let id = result.transactionId {
                    completion(.success(id))
                } else {
                    completion(.failure(.internalError(message: result.error ?? "Unknown Error", error: nil)))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
