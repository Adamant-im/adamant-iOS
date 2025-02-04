//
//  ERC20ApiServiceProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 25.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit
import Foundation
import web3swift
@preconcurrency import Web3Core

final class ERC20ApiServiceProtocolMock: ERC20ApiServiceProtocol {
    
    var keystoreManager: KeystoreManager?
    var api: EthApiCore!
    var web3: Web3!
    var contractAddress: EthereumAddress!
    
    func requestERC20<Output>(
        token: ERC20Token,
        _ body: @escaping @Sendable (ERC20) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await api.performRequest(
            origin: .mock
        ) { _ in
            let erc20 = ERC20(web3: self.web3, provider: self.web3.provider, address: self.contractAddress)
            return try await body(erc20)
        }
    }
    
    func requestWeb3<Output>(
        waitsForConnectivity: Bool,
        _ request: @escaping @Sendable (Web3) async throws -> Output
    ) async -> WalletServiceResult<Output>  {
        await api.performRequest(
            origin: .mock
        ) { _ in
            try await request(self.web3)
        }
    }
    
    func requestApiCore<Output>(
        waitsForConnectivity: Bool,
        _ request: @escaping @Sendable (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await request(
            api.apiCore,
            .mock
        ).mapError { $0.asWalletServiceError() }
    }
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) async {
        await api.setKeystoreManager(keystoreManager)
    }
    
    var nodesInfo: CommonKit.NodesListInfo {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var nodesInfoPublisher: CommonKit.AnyObservable<CommonKit.NodesListInfo> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func healthCheck() {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
