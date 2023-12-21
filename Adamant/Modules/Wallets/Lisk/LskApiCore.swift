//
//  LskApiCore.swift
//  Adamant
//
//  Created by Andrew G on 13.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import LiskKit

class LskApiCore: BlockchainHealthCheckableService {
    func makeClient(node: CommonKit.Node) -> APIClient {
        .init(options: .init(
            nodes: [.init(origin: node.asString())],
            nethash: .mainnet,
            randomNode: false
        ))
    }
    
    func request<Output>(
        node: CommonKit.Node,
        body: @escaping @Sendable (
            _ client: APIClient,
            _ completion: @escaping @Sendable (LiskKit.Result<Output>) -> Void
        ) -> Void
    ) async -> WalletServiceResult<Output> {
        await withCheckedContinuation { continuation in
            body(makeClient(node: node)) { result in
                continuation.resume(returning: result.asWalletServiceResult())
            }
        }
    }
    
    func request<Output>(
        node: CommonKit.Node,
        _ body: @Sendable @escaping (APIClient) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        let client = makeClient(node: node)
        
        do {
            return .success(try await body(client))
        } catch {
            return .failure(mapError(error))
        }
    }
    
    func getStatusInfo(node: CommonKit.Node) async -> WalletServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        
        return await request(node: node) { client, completion in
            LiskKit.Node(client: client).info { completion($0) }
        }.map { model in
            .init(
                ping: Date.now.timeIntervalSince1970 - startTimestamp,
                height: model.data.height ?? .zero,
                wsEnabled: false,
                wsPort: nil,
                version: nil
            )
        }
    }
}

private extension LiskKit.Result {
    func asWalletServiceResult() -> WalletServiceResult<R> {
        switch self {
        case let .success(response):
            return .success(response)
        case let .error(error):
            return .failure(mapError(error))
        }
    }
}

private func mapError(_ error: APIError) -> WalletServiceError {
    switch error {
    case .noNetwork:
        return .networkError
    default:
        return .remoteServiceError(message: error.message, error: error)
    }
}

private func mapError(_ error: Error) -> WalletServiceError {
    if let error = error as? APIError {
        return mapError(error)
    }
    
    return .remoteServiceError(message: error.localizedDescription, error: error)
}
