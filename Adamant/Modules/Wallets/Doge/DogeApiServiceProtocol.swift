//
//  DogeApiServiceProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 17.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol DogeApiServiceProtocol: ApiServiceProtocol {
    
    var api: DogeInternalApiProtocol { get }
    
    func request<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output>
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo>
}
