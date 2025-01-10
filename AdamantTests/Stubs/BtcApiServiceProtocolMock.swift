//
//  BtcApiServiceProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 09.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit
import Foundation

final class BtcApiServiceProtocolMock: BtcApiServiceProtocol {
    
    var api: BtcApiCore!
    
    func request<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request(origin: NodeOrigin(url: URL(string: "http://samplenodeorigin.com")!)) { core, origin in
            await request(core, origin)
        }
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        return .failure(.networkError)
    }
    
    var nodesInfo: CommonKit.NodesListInfo {
        fatalError()
    }
    
    var nodesInfoPublisher: CommonKit.AnyObservable<CommonKit.NodesListInfo> {
        fatalError()
    }
    
    func healthCheck() {
        fatalError()
    }
}
