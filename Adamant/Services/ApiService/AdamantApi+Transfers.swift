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
    func transferFunds(
        transaction: UnregisteredTransaction
    ) async throws -> UInt64 {
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
