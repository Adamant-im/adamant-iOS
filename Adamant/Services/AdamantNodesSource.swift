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
			
			NotificationCenter.default.post(name: Notification.Name.NodesSource.nodesChanged, object: self, userInfo: [AdamantUserInfoKey.nodesSource.nodes: nodes])
		}
	}
	
	var defaultNodes: [Node]
	
	
	// MARK: - Ctor
	
	init(defaultNodes: [Node]) {
		self.defaultNodes = defaultNodes
		self.nodes = defaultNodes
	}
	
	
	// MARK: - Functions
	
	func getNewNode() -> Node {
		let index = Int(arc4random_uniform(UInt32(nodes.count)))
		return nodes[index]
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
			let nds = try JSONDecoder().decode([Node].self, from: data)
			nodes = nds
		} catch {
			nodes = defaultNodes
			print(error.localizedDescription)
		}
	}
}
