//
//  AdamantNodesSource.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class AdamantNodesSource: NodesSource {
    // MARK: - Dependencies
    
    private let apiService: ApiService
    private let healthCheckService: HealthCheckService
    private let securedStore: SecuredStore
    
    // MARK: - Properties
    
    @Atomic private var _nodes: [Node] = [] {
        didSet {
            healthCheckService.nodes = nodes
            nodesUpdate()
        }
    }
    
    @Atomic private var _preferTheFastestNode = preferTheFastestNodeDefault {
        didSet {
            savePreferTheFastestNode(preferTheFastestNode)
            
            guard preferTheFastestNode else { return }
            sendNodesUpdateNotification()
        }
    }
    
    var nodes: [Node] {
        get { _nodes }
        set { _nodes = newValue }
    }
    
    var preferTheFastestNode: Bool {
        get { _preferTheFastestNode }
        set { _preferTheFastestNode = newValue }
    }
    
    private let defaultNodesGetter: () -> [Node]
    @Atomic private var timer: Timer?
    @Atomic private var savedNodes: [Node] = []
    
    // MARK: - Ctor
    
    init(
        apiService: ApiService,
        healthCheckService: HealthCheckService,
        securedStore: SecuredStore,
        defaultNodesGetter: @escaping () -> [Node]
    ) {
        self.apiService = apiService
        self.healthCheckService = healthCheckService
        self.securedStore = securedStore
        self.defaultNodesGetter = defaultNodesGetter
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.healthCheck()
        }
        
        let savedPreferTheFastestNode = UserDefaults.standard.object(
            forKey: UserDefaults.NodesSource.preferTheFastestNodeKey
        ) as? Bool
        
        let preferTheFastestNode = savedPreferTheFastestNode ?? preferTheFastestNodeDefault
        
        if savedPreferTheFastestNode == nil {
            savePreferTheFastestNode(preferTheFastestNodeDefault)
        }
        
        self.preferTheFastestNode = preferTheFastestNode
        healthCheckService.delegate = self
        healthCheckService.nodes = nodes
        setHealthCheckTimer()
        loadNodes()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Tools
    
    func setDefaultNodes() {
        nodes = defaultNodesGetter()
    }
    
    func getAllowedNodes(needWS: Bool) -> [Node] {
        healthCheckService.nodes.getAllowedNodes(
            sortedBySpeedDescending: preferTheFastestNode,
            needWS: needWS
        )
    }
    
    func nodesUpdate() {
        healthCheck()
        saveNodes()
    }
    
    func healthCheck() {
        healthCheckService.healthCheck()
    }
    
    private func savePreferTheFastestNode(_ newValue: Bool) {
        UserDefaults.standard.set(
            newValue,
            forKey: UserDefaults.NodesSource.preferTheFastestNodeKey
        )
    }
    
    private func sendNodesUpdateNotification() {
        NotificationCenter.default.post(
            name: Notification.Name.NodesSource.nodesUpdate,
            object: self,
            userInfo: [:]
        )
    }
    
    private func saveNodes() {
        guard nodes != savedNodes else { return }
        securedStore.set(nodes, for: StoreKey.NodesSource.nodes)
        savedNodes = securedStore.get(StoreKey.NodesSource.nodes) ?? []
    }
    
    private func loadNodes() {
        savedNodes = securedStore.get(StoreKey.NodesSource.nodes) ?? defaultNodesGetter()
        nodes = securedStore.get(StoreKey.NodesSource.nodes) ?? defaultNodesGetter()
    }
    
    private func setHealthCheckTimer() {
        timer = Timer.scheduledTimer(
            withTimeInterval: regularHealthCheckTimeInteval,
            repeats: true
        ) { [weak healthCheckService] _ in
            healthCheckService?.healthCheck()
        }
    }
}

extension AdamantNodesSource: HealthCheckDelegate {
    func healthCheckUpdate() {
        sendNodesUpdateNotification()
        saveNodes()
    }
}

private let regularHealthCheckTimeInteval: TimeInterval = 300
private let preferTheFastestNodeDefault = true
