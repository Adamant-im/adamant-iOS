//
//  ERC20ApiService.swift
//  Adamant
//
//  Created by Andrew G on 13.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import web3swift
@preconcurrency import Web3Core
import CommonKit

final class ERC20ApiService: EthApiService, @unchecked Sendable {
    func requestERC20<Output>(
        token: ERC20Token,
        _ body: @Sendable @escaping (ERC20) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        let contractAddress = EthereumAddress(token.contractAddress) ?? .zero
        
        return await requestWeb3(waitsForConnectivity: false) { web3 in
            let erc20 = ERC20(web3: web3, provider: web3.provider, address: contractAddress)
            return try await body(erc20)
        }
    }
}
