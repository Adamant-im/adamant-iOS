//
//  AdamantApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

///
/// I need to override HealthCheckWrapped because of now we have an option to cancel the tasks
/// and there is some situations when we are waiting for connection on the node and recursevly calling `request`
/// function without any break condition and that is bad and unsafe. I've added a functionality of pushing the assosiated with the task `UUID`
/// and checking it for a cancellation before doing something in the recursive function
/// `request(waitsForConnectivity:taskId:isCancelled:_ request:)`
///
/// We are creating a `AdamantApiTask` without any `Task` in it to defer a `Task` execution to store it in the storage before the execution
///

private final actor TasksStorage {
    private var adamantApiTaskStorage: [UUID: CancellableTask] = [:]

    init() {}

    func getTask(id: UUID) -> CancellableTask? {
        return adamantApiTaskStorage[id]
    }

    func addTask(_ task: CancellableTask, id: UUID) {
        adamantApiTaskStorage[id] = task
    }

    func removeTask(id: UUID) {
        adamantApiTaskStorage[id] = nil
    }

    func cancelAll() {
        adamantApiTaskStorage.forEach { _, task in
            task.cancel()
        }
    }
}

public final class AdamantApiService: @unchecked Sendable {
    private let tasksStorage = TasksStorage()
    public let adamantCore: AdamantCore
    public let service: AdamantHealthCheck

    public init(
        healthCheckWrapper: AdamantHealthCheck,
        adamantCore: AdamantCore
    ) {
        service = healthCheckWrapper
        self.adamantCore = adamantCore
    }

    public func request<Output>(
        waitsForConnectivity: Bool = false,
        timeout: TimeInterval? = nil,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        let taskId: UUID = .init()
        let task = AdamantApiTask<Output>(id: taskId)

        await tasksStorage.addTask(task, id: taskId)
        defer {
            Task {
                await tasksStorage.removeTask(id: taskId)
            }
        }

        task.startTask(
            Task {
                if let timeout {
                    await service.request(
                        waitsForConnectivity: waitsForConnectivity,
                        timeout: timeout,
                        taskId: taskId,
                        isCancelled: {
                            await tasksStorage.getTask(id: taskId)?.isCancelled ?? true
                        }
                    ) { admApiCore, origin in
                        await request(admApiCore.apiCore, origin)
                    }
                } else {
                    await service.request(
                        waitsForConnectivity: waitsForConnectivity,
                        taskId: taskId,
                        isCancelled: {
                            await tasksStorage.getTask(id: taskId)?.isCancelled ?? true
                        }
                    ) { admApiCore, origin in
                        await request(admApiCore.apiCore, origin)
                    }
                }
            }
        )
        return await task.value
    }

    public func cancelCurrentTasks() async {
        await tasksStorage.cancelAll()
    }
}

extension AdamantApiServiceProtocol {
    public func sendTransaction(
        path: String,
        transaction: UnregisteredTransaction
    ) async -> ApiServiceResult<UInt64> {
        await sendTransaction(path: path, transaction: transaction, timeout: nil)
    }
}

extension AdamantApiService: AdamantApiServiceProtocol {
    @MainActor
    public var nodesInfoPublisher: AnyObservable<NodesListInfo> { service.nodesInfoPublisher }

    @MainActor
    public var nodesInfo: NodesListInfo { service.nodesInfo }

    public func healthCheck() { service.healthCheck() }
}

public final class AdamantHealthCheck: BlockchainHealthCheckWrapper<AdamantApiCore> {
    func request<Output>(
        waitsForConnectivity: Bool,
        timeout: TimeInterval? = nil,
        taskId: UUID,
        isCancelled: () async -> Bool,
        _ requestAction: (AdamantApiCore, NodeOrigin) async -> Result<Output, AdamantApiCore.Error>
    ) async -> Result<Output, AdamantApiCore.Error> {
        var usedNodesIds: Set<UUID> = .init()
        var lastConnectionError: AdamantApiCore.Error?

        /// Check the cancellation of the task from the outside
        guard await !isCancelled() else {
            return .failure(.requestCancelled)
        }

        while true {
            let node = await nodesForRequest(waitsForConnectivity: waitsForConnectivity)
                .first { !usedNodesIds.contains($0.id) }

            guard let node else { break }
            usedNodesIds.insert(node.id)
            let response = await requestAction(service, node.preferredOrigin)

            switch response {
            case .success:
                return response
            case let .failure(error):
                guard error.isNetworkError else { return response }
                lastConnectionError = error
            }
        }

        healthCheck()

        if waitsForConnectivity {
            return await request(
                waitsForConnectivity: waitsForConnectivity,
                taskId: taskId,
                isCancelled: isCancelled,
                requestAction
            )
        }

        let finalError: AdamantApiCore.Error
        if let error = lastConnectionError {
            finalError = error
        } else if nodes.contains(where: { $0.isEnabled }) {
            finalError = .networkError(error: ApiServiceError.noNetworkError)
        } else {
            finalError = .noEndpointsAvailable(nodeGroupName: name)
        }

        return .failure(finalError)
    }
}
