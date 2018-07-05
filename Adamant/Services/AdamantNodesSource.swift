//
//  AdamantNodesSource.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import SPLPing

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
    
    func getValidNode(_ completion: @escaping ((Node?) -> Void)) {
        if let node = currentNodes.first {
            testNode(node: node) { (result) in
                switch result {
                case .passed:
                    completion(node)
                    break
                case .failed, .notTested:
                    if let index = self.currentNodes.index(of: node) {
                        self.currentNodes.remove(at: index)
                    }
                    self.getValidNode(completion)
                    break
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func pingNodes() {
        for index in 0..<self.nodes.count {
            if let address = self.nodes[index].hostAddress() {
                SPLPing.pingOnce(address, configuration: SPLPingConfiguration(pingInterval: 1, timeoutInterval: 1, timeToLive: 1)) { response in
                    let latency = Int(response.duration * 1000)
                    
                    SPLPing.pingOnce(address, configuration: SPLPingConfiguration(pingInterval: 1, timeoutInterval: 1, timeToLive: 1)) { response in
                        let latency = Int(response.duration * 1000)
                        
                        SPLPing.pingOnce(address, configuration: SPLPingConfiguration(pingInterval: 1, timeoutInterval: 1, timeToLive: 1)) { response in
                            let latency = Int(response.duration * 1000)
                            
                            self.nodes[index].latency = latency
                            
                            self.currentNodes = self.nodes.sorted(by: { (n1, n2) -> Bool in
                                return n1.latency > n2.latency
                            })
                        }
                    }
                }
            }
        }
    }
    
    func ping(node: Node, completion: @escaping ((Int) -> Void)) {
        if let address = node.hostAddress() {
            SPLPing.pingOnce(address, configuration: SPLPingConfiguration(pingInterval: 1, timeoutInterval: 1, timeToLive: 1)) { response in
                let latency = Int(response.duration * 1000)
                
                SPLPing.pingOnce(address, configuration: SPLPingConfiguration(pingInterval: 1, timeoutInterval: 1, timeToLive: 1)) { response in
                    let latency = Int(response.duration * 1000)
                    
                    SPLPing.pingOnce(address, configuration: SPLPingConfiguration(pingInterval: 1, timeoutInterval: 1, timeToLive: 1)) { response in
                        let latency = Int(response.duration * 1000)
                        completion(latency)
                        
                        if let index = self.nodes.index(of: node) {
                            self.nodes[index].latency = latency
                        }
                        
                        self.currentNodes = self.nodes.sorted(by: { (n1, n2) -> Bool in
                            return n1.latency > n2.latency
                        })
                    }
                }
            }
        } else {
            completion(Int.max)
        }
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
            currentNodes = nodes
            pingNodes()
			return
		}
		
		do {
			let nds = try JSONDecoder().decode([Node].self, from: data)
			nodes = nds
		} catch {
			nodes = defaultNodes
			print(error.localizedDescription)
		}
        currentNodes = nodes
        pingNodes()
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
            case .success(_):
                testState = .passed
                
            case .failure(let error):
                print(error)
                testState = .failed
            }
            completion(testState)
        }
    }
}
