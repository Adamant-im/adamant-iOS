//
//  HealthCheckWrapper.swift
//  Adamant
//
//  Created by Andrew G on 22.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine
import UIKit

public protocol HealthCheckableError: Error {
    var isNetworkError: Bool { get }
    
    static func noEndpointsError(nodeGroupName: String) -> Self
}

open class HealthCheckWrapper<Service, Error: HealthCheckableError> {
    @ObservableValue public private(set) var nodes: [Node] = .init()
    @ObservableValue public private(set) var sortedAllowedNodes: [Node] = .init()
    
    public let service: Service
    public let isActive: Bool
    public let name: String
    
    private let normalUpdateInterval: TimeInterval
    private let crucialUpdateInterval: TimeInterval
    
    @Atomic public var fastestNodeMode = true
    @Atomic public var healthCheckTimerSubscription: AnyCancellable?
    @Atomic public var subscriptions: Set<AnyCancellable> = .init()
    
    @Atomic private var previousAppState: UIApplication.State?
    @Atomic private var lastUpdateTime: Date?
    
    public var chosenFastestNodeId: UUID? {
        fastestNodeMode
            ? sortedAllowedNodes.first?.id
            : nil
    }
    
    public init(
        service: Service,
        isActive: Bool,
        name: String,
        normalUpdateInterval: TimeInterval,
        crucialUpdateInterval: TimeInterval,
        connection: AnyObservable<Bool>,
        nodes: AnyObservable<[Node]>
    ) {
        self.service = service
        self.isActive = isActive
        self.name = name
        self.normalUpdateInterval = normalUpdateInterval
        self.crucialUpdateInterval = crucialUpdateInterval
        
        let connection = connection
            .removeDuplicates()
            .filter { $0 }
        
        nodes
            .removeDuplicates { !$0.doesNeedHealthCheck($1) }
            .combineLatest(connection)
            .sink { [weak self] _ in self?.healthCheck() }
            .store(in: &subscriptions)
        
        nodes
            .removeDuplicates()
            .sink { [weak self] in self?.updateNodes($0) }
            .store(in: &subscriptions)
        
        $sortedAllowedNodes
            .map { $0.isEmpty }
            .removeDuplicates()
            .sink { [weak self] _ in self?.updateHealthCheckTimerSubscription() }
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
    
    public func request<Output>(
        _ request: @Sendable (Service, NodeOrigin) async -> Result<Output, Error>
    ) async -> Result<Output, Error> {
        let nodesList = fastestNodeMode
            ? sortedAllowedNodes
            : sortedAllowedNodes.shuffled()
        
        var lastConnectionError = nodesList.isEmpty
            ? Error.noEndpointsError(nodeGroupName: name)
            : nil
        
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
        return .failure(lastConnectionError ?? .noEndpointsError(nodeGroupName: name))
    }
    
    open func healthCheck() {
        guard isActive else { return }
        lastUpdateTime = .now
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
        }
    }
    
    func didBecomeActiveAction() {
        defer { previousAppState = .active }
        
        guard
            previousAppState == .background,
            let timeToUpdate = lastUpdateTime?.addingTimeInterval(normalUpdateInterval / 3),
            Date.now > timeToUpdate
        else { return }
        
        healthCheck()
    }
    
    func updateNodes(_ newNodes: [Node]) {
        nodes = newNodes
        
        sortedAllowedNodes = newNodes.getAllowedNodes(
            sortedBySpeedDescending: true,
            needWS: false
        )
    }
}

private extension Sequence where Element == Node {
    func doesNeedHealthCheck<Nodes: Sequence>(
        _ nodes: Nodes
    ) -> Bool where Nodes.Element == Self.Element {
        Set(self.map { NodeComparisonInfo(node: $0) })
            != Set(nodes.map { NodeComparisonInfo(node: $0) })
    }
}

private struct NodeComparisonInfo: Hashable {
    let mainOrigin: NodeOrigin
    let altOrigin: NodeOrigin?
    let isEnabled: Bool
    
    init(node: Node) {
        mainOrigin = node.mainOrigin
        altOrigin = node.altOrigin
        isEnabled = node.isEnabled
    }
}