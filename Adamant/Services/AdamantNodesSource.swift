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
                currentNodes = nodes
            }
            
            NotificationCenter.default.post(name: Notification.Name.NodesSource.nodesChanged, object: self, userInfo: [AdamantUserInfoKey.nodesSource.nodes: nodes])
        }
    }
    
    var defaultNodes: [Node]
    
    private var currentNodes: [Node] = [Node]()
    
    // MARK: - Ctor
    
    init(defaultNodes: [Node]) {
        self.defaultNodes = defaultNodes
        self.nodes = defaultNodes
        self.currentNodes = defaultNodes
    }
    
    // MARK: - Functions
    
    func getNewNode() -> Node {
        let index = Int(arc4random_uniform(UInt32(nodes.count)))
        return nodes[index]
    }
    
    func getValidNode(completion: @escaping ((Node?) -> Void)) {
        if let node = currentNodes.first {
            testNode(node: node) { (result) in
                switch result {
                case .passed:
                    completion(node)
                    break
                case .failed, .notTested:
                    if let index = self.currentNodes.firstIndex(of: node) {
                        self.currentNodes.remove(at: index)
                    }
                    self.getValidNode(completion: completion)
                    break
                }
            }
        } else {
            completion(nil)
        }
    }
    
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
    
    func reloadNodes() {
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
    
    func migrate() {
        reloadNodes()
        nodes.forEach { node in
            if node.host == "185.231.245.26", node.port == 36666 {
                node.host = "23.226.231.225"
            }
        }
        saveNodes()
    }
    
    private func testNode(node: Node, completion: @escaping ((NodeEditorViewController.TestState) -> Void)) {
        var components = URLComponents()
        
        components.host = node.host
        components.scheme = node.scheme.rawValue
        
        var testState: NodeEditorViewController.TestState = .notTested
        
        if let port = node.port {
            components.port = port
        } else {
            components.port = node.scheme.defaultPort
        }
        
        let url: URL
        do {
            url = try components.asURL()
        } catch {
            testState = .failed
            completion(testState)
            return
        }
        
        self.apiService.getNodeVersion(url: url) { result in
            switch result {
            case .success:
                testState = .passed
                
            case .failure(let error):
                print(error)
                testState = .failed
            }
            completion(testState)
        }
    }
}
