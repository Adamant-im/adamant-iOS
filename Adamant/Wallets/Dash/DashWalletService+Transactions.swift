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
        Task {
            do {
                let transaction = try await getTransaction(by: id)
                handleTransactionResponse(id: id, .success(transaction), completion)
            } catch {
                let error = error as? WalletServiceError
                let errorApi = ApiServiceError.internalError(message: error?.message ?? "", error: error)
                handleTransactionResponse(id: id, .failure(errorApi), completion)
            }
        }
    }

    func getTransaction(by hash: String) async throws -> BTCRawTransaction {
        guard let endpoint = DashWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "method": "getrawtransaction",
            "params": [
                hash, true
            ]
        ]

        // MARK: Sending request
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<BTCRawTransaction, Error>) in
            AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
                switch response.result {
                case .success(let data):
                    do {
                        let result = try DashWalletService.jsonDecoder.decode(BTCRPCServerResponce<BTCRawTransaction>.self, from: data)
                        if let transaction = result.result {
                            continuation.resume(returning: transaction)
                        } else {
                            continuation.resume(throwing: WalletServiceError.internalError(message: "Unaviable transaction", error: nil))
                        }
                    } catch {
                        continuation.resume(throwing: WalletServiceError.internalError(message: "Unaviable transaction", error: error))
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: WalletServiceError.internalError(message: "No transaction", error: error))
                }
            }
        }
    }

    func getBlockId(by hash: String?) async throws -> String {
        guard let hash = hash else {
            throw WalletServiceError.internalError(message: "Hash is empty", error: nil)
        }
        
        guard let endpoint = DashWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "method": "getblock",
            "params": [
                hash
            ]
        ]
        
        // MARK: Sending request
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<String, Error>) in
            AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
                switch response.result {
                case .success(let data):
                    do {
                        let result = try DashWalletService.jsonDecoder.decode(BTCRPCServerResponce<BtcBlock>.self, from: data)
                        if let block = result.result {
                            continuation.resume(returning: String(block.height))
                        } else {
                            continuation.resume(throwing: WalletServiceError.internalError(message: "DASH: Parsing block error", error: nil))
                        }
                    } catch {
                        continuation.resume(throwing: WalletServiceError.internalError(message: "DASH: Parsing bloc error", error: error))
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: WalletServiceError.internalError(message: "No block", error: error))
                }
                
            }
        }
    }

    func getUnspentTransactions() async throws -> [UnspentTransaction] {
        guard let endpoint = DashWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        guard let wallet = self.dashWallet else {
            throw WalletServiceError.internalError(message: "DASH Wallet not found", error: nil)
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        let parameters: Parameters = [
            "method": "getaddressutxos",
            "params": [
                wallet.address
            ]
        ]
        
        // MARK: Sending request
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<[UnspentTransaction], Error>) in
            AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
                
                switch response.result {
                case .success(let data):
                    do {
                        let response = try DashWalletService.jsonDecoder.decode(BTCRPCServerResponce<[DashUnspentTransaction]>.self, from: data)
                        
                        if let result = response.result {
                            let transactions = result.map { $0.asUnspentTransaction(with: wallet.publicKey.toCashaddr().data) }
                            continuation.resume(returning: transactions)
                        } else if let error = response.error?.message {
                            continuation.resume(throwing: WalletServiceError.internalError(message: error, error: nil))
                        }
                    } catch {
                        continuation.resume(throwing: WalletServiceError.internalError(message: "DASH Wallet: not a valid response", error: error))
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: WalletServiceError.internalError(message: "DASH Wallet: server not responding", error: error))
                }
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
        guard let endpoint = DashWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DASH endpoint URL")
        }
        
        guard let address = self.dashWallet?.address else {
            completion(.failure(.internalError(message: "DASH Wallet not found", error: nil)))
            return
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]

        let parameters: Parameters = [
            "method": "getaddresstxids",
            "params": [
                address
            ]
        ]

        // MARK: Sending request
        AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            
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
