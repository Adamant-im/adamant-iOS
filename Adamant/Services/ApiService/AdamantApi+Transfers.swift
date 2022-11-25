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
        ) { [weak self] (serverResponse: ApiServiceResult<ServerModelResponse<NormalizedTransaction>>) in
            switch serverResponse {
            case .success(let response):
                guard let self = self, let normalizedTransaction = response.model else {
                    let error = AdamantApiService.translateServerError(response.error)
                    completion(.failure(error))
                    return
                }
                
                guard let transaction = self.adamantCore.makeSignedTransaction(
                    transaction: normalizedTransaction,
                    senderId: sender,
                    keypair: keypair
                ) else {
                    completion(.failure(InternalError.signTransactionFailed.apiServiceErrorWith(error: nil)))
                    return
                }
                
                self.sendTransaction(
                    path: ApiCommands.Transactions.processTransaction,
                    transaction: transaction
                ) { response in
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
