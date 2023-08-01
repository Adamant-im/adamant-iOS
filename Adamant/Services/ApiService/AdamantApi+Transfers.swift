//
//  AdamantApi+Transfers.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

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
    
    func transferFunds(
        sender: String,
        recipient: String,
        amount: Decimal,
        keypair: Keypair
    ) async throws -> UInt64 {
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
            throw InternalError.signTransactionFailed.apiServiceErrorWith(error: nil)
        }
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<UInt64, Error>) in
            sendTransaction(
                path: ApiCommands.Transactions.processTransaction,
                transaction: transaction
            ) { response in
                switch response {
                case .success(let result):
                    if let id = result.transactionId {
                        continuation.resume(returning: id)
                    } else {
                        continuation.resume(
                            throwing: ApiServiceError.internalError(
                                message: result.error ?? "Unknown Error",
                                error: nil
                            )
                        )
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
