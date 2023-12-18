//
//  EthApiCore.swift
//  Adamant
//
//  Created by Andrew G on 30.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import web3swift
import Web3Core

actor EthApiCore {
    let apiCore: APICoreProtocol
    private(set) var keystoreManager: KeystoreManager?
    private var web3Cache: [URL: Web3] = .init()
    
    func performRequest<Success>(
        node: Node,
        _ body: @escaping @Sendable (_ web3: Web3) async throws -> Success
    ) async -> WalletServiceResult<Success> {
        switch await getWeb3(node: node) {
        case let .success(web3):
            do {
                return .success(try await body(web3))
            } catch {
                return .failure(mapError(error))
            }
        case let .failure(error):
            return .failure(error)
        }
    }
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) {
        self.keystoreManager = keystoreManager
        web3Cache = .init()
    }
    
    init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
}

extension EthApiCore: BlockchainHealthCheckableService {
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
}

private extension EthApiCore {
    func getWeb3(node: Node) async -> WalletServiceResult<Web3> {
        guard let url = node.asURL() else {
            return .failure(.internalError(.endpointBuildFailed))
        }
        
        if let web3 = web3Cache[url] {
            return .success(web3)
        }
        
        do {
            let web3 = try await Web3.new(url)
            web3.addKeystoreManager(keystoreManager)
            web3Cache[url] = web3
            return .success(web3)
        } catch {
            return .failure(.internalError(
                message: error.localizedDescription,
                error: error
            ))
        }
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
