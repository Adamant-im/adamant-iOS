//
//  DashWalletService+Transactions.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11.04.2021.
//  Copyright © 2021 Adamant. All rights reserved.
//

import Foundation
import Alamofire
import BitcoinKit
import BitcoinKit.Private

struct DashTransactionsPointer {
    let total: Int
    let transactions: [DashTransaction]
    let hasMore: Bool
}

extension DashWalletService {

    func getTransactions(completion: @escaping (ApiServiceResult<DashTransactionsPointer>) -> Void) {
        guard let address = wallet?.address else {
            completion(.failure(.notLogged))
            return
        }

        requestTransactionsIds(for: address) {
            self.handleTransactionsResponse($0, completion)
        }
    }

    func getNextTransaction(completion: @escaping (ApiServiceResult<DashTransactionsPointer>) -> Void) {
        guard let id = transatrionsIds.last else {
            completion(.success(.init(total: transatrionsIds.count, transactions: [], hasMore: false)))
            return
        }
        getTransaction(by: id) {
            self.handleTransactionResponse(id: id, $0, completion)
        }
    }

    func getTransaction(by hash: String, completion: @escaping (ApiServiceResult<BTCRawTransaction>) -> Void) {
        guard let endpoint = AdamantResources.dashServers.randomElement() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "method": "getrawtransaction",
            "params": [
                hash, true
            ]
        ]

        // MARK: Sending request
        Alamofire.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let result = try DashWalletService.jsonDecoder.decode(BTCRPCServerResponce<BTCRawTransaction>.self, from: data)
                    if let transaction = result.result {
                        completion(.success(transaction))
                    } else {
                        completion(.failure(.internalError(message: "Unaviable transaction", error: nil)))
                    }
                } catch {
                    completion(.failure(.internalError(message: "Unaviable transaction", error: error)))
                }

            case .failure(let error):
                completion(.failure(.internalError(message: "No transaction", error: error)))
            }
        }
    }

    func getBlockId(by hash: String, completion: @escaping (ApiServiceResult<String>) -> Void) {
        guard let endpoint = AdamantResources.dashServers.randomElement() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "method": "getblock",
            "params": [
                hash
            ]
        ]
        
        // MARK: Sending request
        Alamofire.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let result = try DashWalletService.jsonDecoder.decode(BTCRPCServerResponce<BtcBlock>.self, from: data)
                    if let block = result.result {
                        completion(.success(String(block.height)))
                    } else {
                        completion(.failure(.internalError(message: "DASH: Parsing block error", error: nil)))
                    }
                } catch {
                    completion(.failure(.internalError(message: "DASH: Parsing bloc error", error: error)))
                }
                
            case .failure(let error):
                completion(.failure(.internalError(message: "No block", error: error)))
            }
            
        }
    }

    func getUnspentTransactions(_ completion: @escaping (ApiServiceResult<[UnspentTransaction]>) -> Void) {
        guard let endpoint = AdamantResources.dashServers.randomElement() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        guard let wallet = self.dashWallet else {
            completion(.failure(.internalError(message: "DASH Wallet not found", error: nil)))
            return
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "method": "getaddressutxos",
            "params": [
                wallet.address
            ]
        ]
        
        // MARK: Sending request
        Alamofire.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            
            switch response.result {
            case .success(let data):
                do {
                    let response = try DashWalletService.jsonDecoder.decode(BTCRPCServerResponce<[DashUnspentTransaction]>.self, from: data)
                    
                    if let result = response.result {
                        let transactions = result.map { $0.asUnspentTransaction(with: wallet.publicKey.toCashaddr().data) }
                        completion(.success(transactions))
                    } else if let error = response.error?.message {
                        completion(.failure(.internalError(message: error, error: nil)))
                    }
                } catch {
                    completion(.failure(.internalError(message: "DASH Wallet: not a valid response", error: error)))
                }
                
            case .failure(let error):
                completion(.failure(.internalError(message: "DASH Wallet: server not responding", error: error)))
            }
        }
    }

}

// MARK: - Handlers

private extension DashWalletService {

    func handleTransactionsResponse(_ response: ApiServiceResult<[String]>, _ completion: @escaping (ApiServiceResult<DashTransactionsPointer>) -> Void) {
        switch response {
        case .success(let ids):
            transatrionsIds = ids
            getNextTransaction(completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }

    func handleTransactionResponse(id: String, _ response: ApiServiceResult<BTCRawTransaction>, _ completion: @escaping (ApiServiceResult<DashTransactionsPointer>) -> Void) {
        guard let address = wallet?.address else {
            completion(.failure(.notLogged))
            return
        }

        switch response {
        case .success(let rawTransaction):
            if let idx = self.transatrionsIds.firstIndex(of: id) {
                self.transatrionsIds.remove(at: idx)
            }
            let transaction = rawTransaction.asBtcTransaction(DashTransaction.self, for: address)
            completion(.success(.init(total: transatrionsIds.count, transactions: [transaction], hasMore: !transatrionsIds.isEmpty)))
        case .failure(let error):
            completion(.failure(error))
        }
    }

}

// MARK: - Network Requests

private extension DashWalletService {

    func requestTransactionsIds(for address: String, completion: @escaping (ApiServiceResult<[String]>) -> Void) {
        guard let endpoint = AdamantResources.dashServers.randomElement() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        guard let address = self.dashWallet?.address else {
            completion(.failure(.internalError(message: "DASH Wallet not found", error: nil)))
            return
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]

        let parameters: Parameters = [
            "method": "getaddresstxids",
            "params": [
                address
            ]
        ]

        // MARK: Sending request
        Alamofire.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            
            switch response.result {
            case .success(let data):
                do {
                    let response = try DashWalletService.jsonDecoder.decode(BTCRPCServerResponce<[String]>.self, from: data)
                    
                    if let result = response.result {
                        completion(.success(result))
                    } else if let error = response.error?.message {
                        completion(.failure(.internalError(message: error, error: nil)))
                    }
                } catch {
                    completion(.failure(.internalError(message: "DASH Wallet: not a valid response", error: error)))
                }
                
            case .failure(let error):
                completion(.failure(.internalError(message: "DASH Wallet: server not responding", error: error)))
            }
        }
    }

}
