//
//  DashWalletService+Transactions.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11.04.2021.
//  Copyright © 2021 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import BitcoinKit

struct DashTransactionsPointer {
    let total: Int
    let transactions: [DashTransaction]
    let hasMore: Bool
}

extension DashWalletService {

    func getNextTransaction(completion: @escaping @Sendable (ApiServiceResult<DashTransactionsPointer>) -> Void) {
        guard let id = transatrionsIds.last else {
            completion(.success(.init(total: transatrionsIds.count, transactions: [], hasMore: false)))
            return
        }
        Task { @Sendable in
            do {
                let transaction = try await getTransaction(by: id, waitsForConnectivity: false)
                handleTransactionResponse(id: id, .success(transaction), completion)
            } catch {
                let error = error as? WalletServiceError
                let errorApi = ApiServiceError.serverError(error: error?.message ?? .empty)
                handleTransactionResponse(id: id, .failure(errorApi), completion)
            }
        }
    }

    func getTransaction(by hash: String, waitsForConnectivity: Bool) async throws -> BTCRawTransaction {
        let result: BTCRawTransaction? = try await dashApiService.request(
            waitsForConnectivity: waitsForConnectivity
        ) { core, origin in
            let response = await core.sendRequestRPC(
                origin: origin,
                path: .empty,
                request: .init(
                    method: DashApiComand.rawTransactionMethod,
                    params: [.string(hash), .bool(true)]
                )
            )
            
            guard case let .success(data) = response else {
                return .failure(.accountNotFound)
            }
            
            let tx: BTCRawTransaction? = data.serialize()
            return .success(tx)
        }.get()
        
        if let transaction = result {
            return transaction
        } else {
            throw ApiServiceError.serverError(error: "Unaviable transaction")
        }
    }

    func getTransactions(by hashes: [String]) async throws -> [DashTransaction] {
        guard let address = wallet?.address else {
            throw ApiServiceError.notLogged
        }
        
        let params: [RpcRequest] = hashes.compactMap {
            .init(
                method: DashApiComand.rawTransactionMethod,
                params: [.string($0), .bool(true)]
            )
        }
        
        let result: [BTCRawTransaction] = try await dashApiService.request(waitsForConnectivity: false) { core, origin in
            let response = await core.sendRequestRPC(
                origin: origin,
                path: .empty,
                requests: params
            )
            
            guard case let .success(data) = response else {
                return .failure(.accountNotFound)
            }
            
            let res: [BTCRawTransaction] = data.compactMap {
                let tx: BTCRawTransaction? = $0.serialize()
                return tx
            }
            
            return .success(res)
        }.get()
        
        return result.compactMap {
            $0.asBtcTransaction(DashTransaction.self, for: address)
        }
    }
    
    func getBlockId(by hash: String?) async throws -> String {
        guard let hash = hash else {
            throw WalletServiceError.internalError(message: "Hash is empty", error: nil)
        }
        
        let result: BTCRPCServerResponce<BtcBlock> = try await dashApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: .empty,
                method: .post,
                parameters: DashGetBlockDTO(hash: hash),
                encoding: .json
            )
        }.get()
        
        if let block = result.result {
            return String(block.height)
        } else {
            throw WalletServiceError.internalError(message: "DASH: Parsing block error", error: nil)
        }
    }

    func getUnspentTransactions() async throws -> [UnspentTransaction] {
        guard let wallet = dashWallet else {
            throw WalletServiceError.internalError(message: "DASH Wallet not found", error: nil)
        }
        
        let response: BTCRPCServerResponce<[DashUnspentTransaction]> = try await dashApiService.request(waitsForConnectivity: false) {
            core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
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
            throw WalletServiceError.remoteServiceError(message: error, error: nil)
        }

        throw WalletServiceError.internalError(
            message: "DASH Wallet: not a valid response",
            error: nil
        )
    }

}

// MARK: - Handlers

private extension DashWalletService {

    func handleTransactionsResponse(
        _ response: ApiServiceResult<[String]>,
        _ completion: @escaping @Sendable (ApiServiceResult<DashTransactionsPointer>) -> Void
    ) {
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
        let response: BTCRPCServerResponce<[String]> = try await dashApiService.request(waitsForConnectivity: false) {
            core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: .empty,
                method: .post,
                parameters: DashGetAddressTransactionIds(address: address),
                encoding: .json
            )
        }.get()
        
        if let result = response.result {
            return result
        }
        
        throw WalletServiceError.internalError(message: "DASH Wallet: not a valid response", error: nil)
    }

}
