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
    }
    
    func request<Output>(
        _ request: @Sendable (Service, Node) async -> Result<Output, Error>
    ) async -> Result<Output, Error> {
        var lastConnectionError = allowedNodes.isEmpty
        ? Error.noEndpointsError(coin: nodeGroup.name)
        : nil
        
        let nodesList = allowedNodes.isEmpty
            ? nodes.filter { $0.isEnabled }.shuffled()
            : fastestNodeMode
                ? allowedNodes
                : allowedNodes.shuffled()
        
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
        }
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
