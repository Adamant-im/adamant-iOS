//
//  AdamantNodesSource.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantNodesSource: NodesSource {
    // MARK: - Dependencies
    var apiService: ApiService!
    var securedStore: SecuredStore! {
        didSet {
            reloadNodes()
        }
    }
    
    
    // MARK: - Properties
    var nodes: [Node] {
        didSet {
            if nodes.count == 0 {
                nodes = defaultNodes
            }
        
            healthCheck()
        }
    }
    
    var defaultNodes: [Node]
    
    var bestNode: Node {
        get {
            guard !allowedNodes.isEmpty else {
                let index = Int(arc4random_uniform(UInt32(nodes.count)))
                return nodes[index]
            }
            
            return allowedNodes[currentNodeIndex]
        }
    }
    
    private var allowedNodes = [Node]() {
        didSet {
            currentNodeIndex = 0
        }
    }
    
    private var currentNodeIndex: Int = 0 {
        didSet {
            NotificationCenter.default.post(
                name: Notification.Name.NodesSource.nodesChanged,
                object: self,
                userInfo: [AdamantUserInfoKey.nodesSource.nodes: nodes]
            )
        }
    }
    
    // MARK: - Ctor
    
    init(defaultNodes: [Node]) {
        self.defaultNodes = defaultNodes
        self.nodes = defaultNodes
    }
    
    
    // MARK: - Functions
    
    func getSocketNewNode() -> Node {
        return nodes[0]
    }
    
    // MARK: - Tools
    func saveNodes() {
        do {
            let data = try JSONEncoder().encode(nodes)
            guard let raw = String(data: data, encoding: String.Encoding.utf8) else {
                return
            }
            
            securedStore.set(raw, for: StoreKey.nodesSource.nodes)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func bestNodeFailed() {
        guard !allowedNodes.isEmpty else {
            healthCheck()
            return
        }
        
        currentNodeIndex = (currentNodeIndex + 1) % allowedNodes.count
        healthCheck()
    }
    
    func migrate() {
        reloadNodes()
        nodes.forEach { node in
            if node.host == "185.231.245.26", node.port == 36666 {
                node.host = "23.226.231.225"
            }
        }
        saveNodes()
    }
    
    private func reloadNodes() {
        guard let raw = securedStore.get(StoreKey.nodesSource.nodes), let data = raw.data(using: String.Encoding.utf8) else {
            nodes = defaultNodes
            return
        }
        
        do {
            nodes = try JSONDecoder().decode([Node].self, from: data)
        } catch {
            nodes = defaultNodes
            print(error.localizedDescription)
        }
    }
    
    private func healthCheck() {
        allowedNodes = []
        
        apiService.healthCheck(
            nodes: nodes,
            firstWorkingNodeHandler: { [weak self] in self?.allowedNodes = [$0] },
            allowedNodesHandler: { [weak self] in self?.allowedNodes = $0 }
        )
    }
}
