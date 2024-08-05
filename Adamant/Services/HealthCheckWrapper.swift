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
    
    @ObservableValue private(set) var sortedAllowedNodes: [Node] = .init()
    
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
                self?.sortedAllowedNodes = $0.getAllowedNodes(
                    sortedBySpeedDescending: true,
                    needWS: false
                )
            }
            .store(in: &subscriptions)
        
        $sortedAllowedNodes
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
    
    func request<Output>(
        _ request: @Sendable (Service, NodeOrigin) async -> Result<Output, Error>
    ) async -> Result<Output, Error> {
        var lastConnectionError = sortedAllowedNodes.isEmpty
            ? Error.noEndpointsError(coin: nodeGroup.name)
            : nil
        
        let nodesList = fastestNodeMode
            ? sortedAllowedNodes
            : sortedAllowedNodes.shuffled()
        
        for node in nodesList {
            let response = await request(service, node.preferredOrigin)
            
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
            every: sortedAllowedNodes.isEmpty
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
}

private extension Node {
    func doesNeedHealthCheck(_ node: Node) -> Bool {
        mainOrigin != node.mainOrigin ||
        altOrigin != node.altOrigin ||
        isEnabled != node.isEnabled
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
