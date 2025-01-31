//
//  DashApiServiceProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 23.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol DashApiServiceProtocol: ApiServiceProtocol {
    func request<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output>
}
