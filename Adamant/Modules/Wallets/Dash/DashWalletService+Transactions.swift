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
        let result: BTCRPCServerResponce<BTCRawTransaction> = try await dashApiService.request {
            core, node in
            await core.sendRequestJson(
                node: node,
                path: .empty,
                method: .post,
                parameters: DashGetRawTransactionDTO(hash: hash),
                encoding: .json
            )
        }.get()
        
        if let transaction = result.result {
            return transaction
        } else {
            throw ApiServiceError.serverError(error: "Unaviable transaction")
        }
    }

    func getTransactions(by hashes: [String]) async throws -> [DashTransaction] {
        guard let address = wallet?.address else {
            throw ApiServiceError.notLogged
        }

        let parameters: [DashGetRawTransactionDTO] = hashes.map { .init(hash: $0) }
        
        let result: [BTCRPCServerResponce<BTCRawTransaction>] = try await dashApiService.request {
            core, node in
            await core.sendRequestJson(
                node: node,
                path: .empty,
                method: .post,
                parameters: parameters,
                encoding: .json
            )
        }.get()
        
        return result.compactMap { $0.result?.asBtcTransaction(DashTransaction.self, for: address) }
    }
    
    func getBlockId(by hash: String?) async throws -> String {
        guard let hash = hash else {
            throw ApiServiceError.internalError(message: "Hash is empty", error: nil)
        }
        
        let result: BTCRPCServerResponce<BtcBlock> = try await dashApiService.request { core, node in
            await core.sendRequestJson(
                node: node,
                path: .empty,
                method: .post,
                parameters: DashGetBlockDTO(hash: hash),
                encoding: .json
            )
        }.get()
        
        if let block = result.result {
            return String(block.height)
        } else {
            throw ApiServiceError.internalError(message: "DASH: Parsing block error", error: nil)
        }
    }

    func getUnspentTransactions() async throws -> [UnspentTransaction] {
        guard let wallet = dashWallet else {
            throw WalletServiceError.internalError(message: "DASH Wallet not found", error: nil)
        }
        
        let response: BTCRPCServerResponce<[DashUnspentTransaction]> = try await dashApiService.request {
            core, node in
            await core.sendRequestJson(
                node: node,
                path: .empty,
                method: .post,
                parameters: DashGetUnspentTransactionDTO(address: wallet.address),
                encoding: .json
            )
        }.get()
        
        if let result = response.result {
            return result.map {
                $0.asUnspentTransaction(lockScript: wallet.addressEntity.lockingScript)
            }
        } else if let error = response.error?.message {
            throw WalletServiceError.internalError(message: error, error: nil)
        }

        throw WalletServiceError.internalError(
            message: "DASH Wallet: not a valid response",
            error: nil
        )
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

extension DashWalletService {
    func requestTransactionsIds(for address: String) async throws -> [String] {
        let response: BTCRPCServerResponce<[String]> = try await dashApiService.request {
            core, node in
            await core.sendRequestJson(
                node: node,
                path: .empty,
                method: .post,
                parameters: DashGetAddressTransactionIds(address: address),
                encoding: .json
            )
        }.get()
        
        if let result = response.result {
            return result
        }
        
        throw ApiServiceError.internalError(message: "DASH Wallet: not a valid response", error: nil)
    }

}
