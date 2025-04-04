//
//  ERC20ApiServiceProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 25.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
@preconcurrency import Web3Core
import web3swift

protocol ERC20ApiServiceProtocol: EthApiServiceProtocol {

    var keystoreManager: KeystoreManager? { get async }

    func requestERC20<Output>(
        token: ERC20Token,
        _ body: @Sendable @escaping (ERC20) async throws -> Output
    ) async -> WalletServiceResult<Output>
}
