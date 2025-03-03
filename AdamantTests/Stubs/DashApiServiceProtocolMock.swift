//
//  DashApiServiceProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 23.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit
import Foundation

final class DashApiServiceProtocolMock: DashApiServiceProtocol {
    var api: DashApiCore!
    
    func request<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request(origin: .mock) { core, origin in
            await request(core, origin)
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        return .failure(.networkError)
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
