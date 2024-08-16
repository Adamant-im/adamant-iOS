//
//  HealthCheckWrapper.swift
//  Adamant
//
//  Created by Andrew G on 22.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import Combine
import UIKit

protocol HealthCheckableError: Error {
    var isNetworkError: Bool { get }
    var isRequestCancelledError: Bool { get }
    
    static func noEndpointsError(coin: String) -> Self
}

class HealthCheckWrapper<Service, Error: HealthCheckableError> {
    @ObservableValue var nodes: [Node] = .init()
    
    let service: Service
    let normalUpdateInterval: TimeInterval
    let crucialUpdateInterval: TimeInterval
    let nodeGroup: NodeGroup
    
    @Atomic var fastestNodeMode = true
    @Atomic var healthCheckTimerSubscription: AnyCancellable?
    @Atomic var subscriptions: Set<AnyCancellable> = .init()
    
    @Atomic private var previousAppState: UIApplication.State?
    @Atomic private var lastUpdateTime = Date()
    
    @ObservableValue private var allowedNodes: [Node] = .init()
    
    var preferredNodeIds: [UUID] {
        fastestNodeMode
            ? [allowedNodes.first?.id].compactMap { $0 }
            : []
    }
    
    init(
        service: Service,
        normalUpdateInterval: TimeInterval,
        crucialUpdateInterval: TimeInterval,
        nodeGroup: NodeGroup
    ) {
        self.service = service
        self.normalUpdateInterval = normalUpdateInterval
        self.crucialUpdateInterval = crucialUpdateInterval
        self.nodeGroup = nodeGroup
        
        $nodes
            .removeDuplicates { !$0.doesNeedHealthCheck($1) }
            .sink { [weak self] _ in self?.healthCheck() }
            .store(in: &subscriptions)
        
        $nodes
            .removeDuplicates()
            .sink { [weak self] in
                self?.allowedNodes = $0.getAllowedNodes(
                    sortedBySpeedDescending: true,
                    needWS: false
                )
            }
            .store(in: &subscriptions)
        
        $allowedNodes
            .map { $0.isEmpty }
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateHealthCheckTimerSubscription() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantReachabilityMonitor.reachabilityChanged, object: nil)
            .compactMap {
                $0.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool
            }
            .removeDuplicates()
            .filter { $0 == true }
            .sink { [weak self] _ in self?.healthCheck() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
            .sink { [weak self] _ in self?.didBecomeActiveAction() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: UIApplication.willResignActiveNotification, object: nil)
            .sink { [weak self] _ in self?.previousAppState = .background }
            .store(in: &subscriptions)
    }
    
    func waitingRequest<Output>(
        _ requestAction: @Sendable @escaping (Service, Node) async -> Result<Output, Error>
    ) async -> Result<Output, Error> {
        guard allowedNodes.isEmpty else {
            return await handleRequest(requestAction: requestAction)
        }
        
        return await withCheckedContinuation { [weak self] continuation in
            guard let self = self else {
                return
            }
            $allowedNodes
                .filter { !$0.isEmpty }
                .prefix(1)
                .sink { [weak self] _ in
                    guard let self = self else {
                        continuation.resume(returning: .failure(.noEndpointsError(coin: NodeGroup.adm.name)))
                        return
                    }
                    Task {
                        let result = await self.handleRequest(requestAction: requestAction)
                        continuation.resume(returning: result)
                    }
                }
                .store(in: &subscriptions)
        }
    }
    
    func request<Output>(
        _ request: @Sendable (Service, Node) async -> Result<Output, Error>
    ) async -> Result<Output, Error> {
        let nodesList = fastestNodeMode
            ? allowedNodes
            : allowedNodes.shuffled()
        
        var lastConnectionError = nodesList.isEmpty
        ? Error.noEndpointsError(coin: nodeGroup.name)
        : nil
        
        for node in nodesList {
            let response = await request(service, node)
            
            switch response {
            case .success:
                return response
            case let .failure(error):
                guard error.isNetworkError else { return response }
                lastConnectionError = error
            }
        }
        
        if lastConnectionError != nil { healthCheck() }
        return .failure(lastConnectionError ?? Error.noEndpointsError(coin: nodeGroup.name))
    }
    
    func healthCheck() {
        updateHealthCheckTimerSubscription()
    }
}

private extension HealthCheckWrapper {
    func updateHealthCheckTimerSubscription() {
        healthCheckTimerSubscription = Timer.publish(
            every: allowedNodes.isEmpty
                ? crucialUpdateInterval
                : normalUpdateInterval,
            on: .main,
            in: .default
        ).autoconnect().sink { [weak self] _ in
            self?.healthCheck()
            self?.lastUpdateTime = Date()
        }
    }
    
    func didBecomeActiveAction() {
        defer { previousAppState = .active }
        
        guard previousAppState == .background,
              Date() > lastUpdateTime.addingTimeInterval(normalUpdateInterval / 3)
        else { return }
        
        healthCheck()
        lastUpdateTime = Date()
    }
    
    private func handleRequest<Output>(
        requestAction: @Sendable @escaping (Service, Node) async -> Result<Output, Error>
    ) async -> Result<Output, Error> {
        let result = await request(requestAction)
        return await handleResult(result: result, requestAction: requestAction)
    }
    
    private func handleResult<Output>(
        result: Result<Output, Error>,
        requestAction: @Sendable @escaping (Service, Node) async -> Result<Output, Error>
    ) async -> Result<Output, Error> {
        guard case .failure(let failure) = result,
              let apiServiceError = failure as? ApiServiceError,
              apiServiceError.isNetworkError || apiServiceError == .noEndpointsError(coin: nodeGroup.name) else {
            return result
        }
        return await waitingRequest(requestAction)
    }
}

private extension Node {
    func doesNeedHealthCheck(_ node: Node) -> Bool {
        scheme != node.scheme ||
        host != node.host ||
        isEnabled != node.isEnabled ||
        port != node.port
    }
}

private extension Sequence where Element == Node {
    func doesNeedHealthCheck<Nodes: Sequence>(_ nodes: Nodes) -> Bool where Nodes.Element == Self.Element {
        let firstNodes = Dictionary(uniqueKeysWithValues: map { ($0.id, $0) })
        let secondNodes = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        guard Set(firstNodes.keys) == Set(secondNodes.keys) else { return true }
        
        return firstNodes.contains { id, firstNode in
            secondNodes[id]?.doesNeedHealthCheck(firstNode) ?? true
        }
    }
}
