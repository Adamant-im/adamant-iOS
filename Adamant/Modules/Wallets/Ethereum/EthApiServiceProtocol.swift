//
//  EthApiServiceProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 16.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import web3swift
@preconcurrency import Web3Core

protocol EthApiServiceProtocol: ApiServiceProtocol {
    func requestWeb3<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (Web3) async throws -> Output
    ) async -> WalletServiceResult<Output>
    
    func requestApiCore<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output>
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) async
}
