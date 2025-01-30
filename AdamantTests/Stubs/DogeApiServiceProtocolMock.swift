//
//  DogeApiServiceProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 17.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit
import Foundation

final class DogeApiServiceProtocolMock: DogeApiServiceProtocol, DogeInternalApiProtocol {
    
    var api: DogeInternalApiProtocol {
        self
    }
    
    var _api: DogeApiCore!
    
    func request<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await _api.request(origin: NodeOrigin(url: URL(string: "http://samplenodeorigin.com")!)) { core, origin in
            await request(core, origin)
        }
    }
    
    func request<Output>(
        waitsForConnectivity: Bool,
        _ requestAction: @Sendable (DogeApiCore, NodeOrigin) async -> WalletServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await requestAction(_api, NodeOrigin(url: URL(string: "http://samplenodeorigin.com")!))
    }
    
    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        return .failure(.networkError)
    }
    
    var nodesInfo: NodesListInfo {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var nodesInfoPublisher: AnyObservable<NodesListInfo> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func healthCheck() {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
