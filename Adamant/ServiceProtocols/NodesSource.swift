//
//  NodesSource.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Notifications
extension Notification.Name {
	struct NodesSource {
		/// Raised when node list changed
		static let nodesChanged = Notification.Name("adamant.nodesSource.nodesChanged")
		
		private init() {}
	}
}

extension AdamantUserInfoKey {
	struct nodesSource {
		/// New node list
		static let nodes = "adamant.nodesSource.nodes"
		
		private init() {}
	}
}

// MARK: - SecuredStore keys
extension StoreKey {
	struct nodesSource {
		static let nodes = "nodesSource.nodes"
		
		private init() {}
	}
}

protocol NodesSource {
	var nodes: [Node] { get set }
	var defaultNodes: [Node] { get }
	
	func getNewNode() -> Node
    func getValidNode(_ completion: @escaping ((Node?) -> Void))
	
	func saveNodes()
	func reloadNodes()
}
