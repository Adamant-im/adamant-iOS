//
//  EthApiService.swift
//  Adamant
//
//  Created by Andrew G on 13.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import web3swift
import Web3Core

actor EthApiCore: BlockchainHealthCheckableService {
    let apiCore: APICoreProtocol
    private(set) var keystoreManager: KeystoreManager?

    func makeWeb3(node: Node) async -> WalletServiceResult<Web3> {
        do {
            guard let url = node.asURL() else { throw InternalAPIError.endpointBuildFailed }
            let web3 = try await Web3.new(url)
            web3.addKeystoreManager(keystoreManager)
            return .success(web3)
        } catch {
            return .failure(.internalError(message: error.localizedDescription, error: error))
        }
    }
    
    func performRequest<Success>(
        node: Node,
        _ body: @escaping (_ web3: Web3) async throws -> Success
    ) async -> WalletServiceResult<Success> {
        await makeWeb3(node: node).asyncMap { web3 in
            do {
                return .success(try await body(web3))
            } catch {
                return .failure(mapError(error))
            }
        }.flatMap { $0 }
    }
    
    func performRequest<Success>(
        _ body: @escaping () async throws -> Success
    ) async -> WalletServiceResult<Success> {
        do {
            return .success(try await body())
        } catch {
            return .failure(mapError(error))
        }
    }
    
    func getStatusInfo(node: Node) async -> WalletServiceResult<NodeStatusInfo> {
        await performRequest(node: node) { web3 in
            let startTimestamp = Date.now.timeIntervalSince1970
            let height = try await web3.eth.blockNumber()
            let ping = Date.now.timeIntervalSince1970 - startTimestamp
            
            return .init(
                ping: ping,
                height: Int(height.asDouble()),
                wsEnabled: false,
                wsPort: nil,
                version: nil
            )
        }
    }
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) {
        self.keystoreManager = keystoreManager
    }
    
    init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
}

class EthApiService: WalletApiService {
    let api: BlockchainHealthCheckWrapper<EthApiCore>
    
    var keystoreManager: KeystoreManager? {
        get async { await api.service.keystoreManager }
    }
    
    var preferredNodeIds: [UUID] {
        api.preferredNodeIds
    }
    
    init(api: BlockchainHealthCheckWrapper<EthApiCore>) {
        self.api = api
    }
    
    func healthCheck() {
        api.healthCheck()
    }
    
    func requestWeb3<Output>(
        _ request: @Sendable @escaping (Web3) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await api.request { core, node in
            await core.performRequest(node: node, request)
        }
    }
    
    func requestApiCore<Output>(
        _ request: @Sendable @escaping (APICoreProtocol, Node) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request { core, node in
            await request(core.apiCore, node).mapError { $0.asWalletServiceError() }
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request { core, node in
            await core.getStatusInfo(node: node)
        }
    }
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) async {
        await api.service.setKeystoreManager(keystoreManager)
    }
}

private func mapError(_ error: Error) -> WalletServiceError {
    if let error = error as? Web3Error {
        return error.asWalletServiceError()
    } else if let error = error as? ApiServiceError {
        return error.asWalletServiceError()
    } else if let error = error as? WalletServiceError {
        return error
    } else if let _ = error as? URLError {
        return .networkError
    } else {
        return .remoteServiceError(message: error.localizedDescription)
    }
}
