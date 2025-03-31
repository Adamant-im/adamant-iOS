//
//  KlyNodeApiServiceProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 22.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import LiskKit

// sourcery: AutoMockable
protocol KlyNodeApiServiceProtocol: ApiServiceProtocol {
    
    func requestTransactionsApi<Output>(
        _ request: @Sendable @escaping (Transactions) async throws -> Output
    ) async -> WalletServiceResult<Output>
    
    func requestAccountsApi<Output>(
        _ request: @Sendable @escaping (Accounts) async throws -> Output
    ) async -> WalletServiceResult<Output>
}
