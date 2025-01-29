//
//  EthApiServiceProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 15.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit
import Foundation
import web3swift
@preconcurrency import Web3Core

final class EthApiServiceProtocolMock: EthApiServiceProtocol {
    
    var api: EthApiCore!
    var web3: Web3!
    
    func requestWeb3<Output>(
        waitsForConnectivity: Bool,
        _ request: @escaping @Sendable (Web3) async throws -> Output
    ) async -> WalletServiceResult<Output>  {
        await api.performRequest(
            origin: NodeOrigin(url: URL(string: "http://samplenodeorigin.com")!)
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
            NodeOrigin(url: URL(string: "http://samplenodeorigin.com")!)
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
