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
        // MARK: 1. Prepare params
        let params: [String : Any] = [
            "type": TransactionType.send.rawValue,
            "amount": (amount.shiftedToAdamant() as NSDecimalNumber).uint64Value,
            "recipientId": recipient,
            "senderId": sender,
            "publicKey": keypair.publicKey
        ]
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Normalize transaction
        sendRequest(
            path: ApiCommands.Transactions.normalizeTransaction,
            method: .post,
            parameters: params,
            encoding: .json,
            headers: headers
        ) { (serverResponse: ApiServiceResult<ServerModelResponse<NormalizedTransaction>>) in
            switch serverResponse {
            case .success(let response):
                guard let normalizedTransaction = response.model else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                    return
                }
                
                // MARK: 3.1. Sign transaction
                guard let signature = self.adamantCore.sign(transaction: normalizedTransaction, senderId: sender, keypair: keypair) else {
                    completion(.failure(InternalError.signTransactionFailed.apiServiceErrorWith(error: nil)))
                    return
                }
                
                // MARK: 3.2. Create transaction
                let transaction: [String: Any] = [
                    "type": normalizedTransaction.type.rawValue,
                    "amount": (normalizedTransaction.amount.shiftedToAdamant() as NSDecimalNumber).uint64Value,
                    "senderPublicKey": normalizedTransaction.senderPublicKey,
                    "requesterPublicKey": normalizedTransaction.requesterPublicKey ?? NSNull(),
                    "timestamp": normalizedTransaction.timestamp,
                    "recipientId": normalizedTransaction.recipientId ?? NSNull(),
                    "senderId": sender,
                    "signature": signature
                ]
                
                let params: [String: Any] = [
                    "transaction": transaction
                ]
                
                // MARK: 4. Send
                self.sendRequest(
                    path: ApiCommands.Transactions.processTransaction,
                    method: .post,
                    parameters: params,
                    encoding: .json,
                    headers: headers
                ) { (response: ApiServiceResult<TransactionIdResponse>) in
                    switch response {
                    case .success(let result):
                        if let id = result.transactionId {
                            completion(.success(id))
                        } else {
                            if let error = result.error {
                                completion(.failure(.internalError(message: error, error: nil)))
                            } else {
                                completion(.failure(.internalError(message: "Unknown Error", error: nil)))
                            }
                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
}
