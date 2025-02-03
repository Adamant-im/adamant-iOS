//
//  KlyNodeApiServiceProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 22.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import LiskKit
@testable import Adamant

final class KlyNodeApiServiceProtocolMock: KlyNodeApiServiceProtocol {
    var nodesInfo: NodesListInfo {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var nodesInfoPublisher: AnyObservable<NodesListInfo> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func requestTransactionsApi<Output>(
        _ request: @Sendable @escaping (Transactions) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        do {
            return .success(try await request(Transactions(client: APIClient())))
        } catch {
            return .failure(.internalError(.endpointBuildFailed))
        }
    }
     
    func requestAccountsApi<Output>(
        _ request: @Sendable @escaping (Accounts) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        do {
            return .success(try await request(Accounts(client: APIClient())))
        } catch {
            return .failure(.internalError(.endpointBuildFailed))
        }
    }
    
    func healthCheck() {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
