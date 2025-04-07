//
//  DogeInternalApiProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 17.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

protocol DogeInternalApiProtocol {
    func request<Output>(
        waitsForConnectivity: Bool,
        _ requestAction: @Sendable (DogeApiCore, NodeOrigin) async -> WalletServiceResult<Output>
    ) async -> WalletServiceResult<Output>
}
