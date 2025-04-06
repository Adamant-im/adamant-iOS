//
//  AdamantApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public final class AdamantApiService: @unchecked Sendable {
    @Atomic private var adamantApiTaskStorage: [UUID: CancellableTask] = [:]

    public let adamantCore: AdamantCore
    public let service: BlockchainHealthCheckWrapper<AdamantApiCore>

    public init(
        healthCheckWrapper: BlockchainHealthCheckWrapper<AdamantApiCore>,
        adamantCore: AdamantCore
    ) {
        service = healthCheckWrapper
        self.adamantCore = adamantCore
    }

    public func request<Output>(
        waitsForConnectivity: Bool = false,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        let task = AdamantApiTask<Output>(
            task: Task {
                await service.request(
                    waitsForConnectivity: waitsForConnectivity
                ) { admApiCore, origin in
                    let result = await request(admApiCore.apiCore, origin)
                    do {
                        try Task.checkCancellation()
                    } catch {
                        return .failure(.requestCancelled)
                    }
                    return result
                }
            }
        )
        task.storeIn(taskStorage: &adamantApiTaskStorage)
        defer { task.removeFrom(taskStorage: &adamantApiTaskStorage) }
        return await task.value
    }

    public func cancelCurrentTasks() {
        adamantApiTaskStorage.forEach { _, task in
            task.cancel()
        }
    }
}

extension AdamantApiService: AdamantApiServiceProtocol {
    @MainActor
    public var nodesInfoPublisher: AnyObservable<NodesListInfo> { service.nodesInfoPublisher }

    @MainActor
    public var nodesInfo: NodesListInfo { service.nodesInfo }

    public func healthCheck() { service.healthCheck() }
}
