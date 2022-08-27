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
        /// Raised by NodesSource when need to update current node or list of nodes
        static let nodesUpdate = Notification.Name("adamant.nodesSource.nodesUpdate")
        
        private init() {}
    }
}

// MARK: - SecuredStore keys
extension StoreKey {
    struct NodesSource {
        static let nodes = "nodesSource.nodes"
        
        private init() {}
    }
}

// MARK: - UserDefaults
extension UserDefaults {
    enum NodesSource {
        static let preferTheFastestNodeKey = "nodesSource.preferTheFastestNode"
    }
}

protocol NodesSource: AnyObject {
    var nodes: [Node] { get set }
    var preferTheFastestNode: Bool { get set }
    
    func setDefaultNodes()
    func getAllowedNodes(needWS: Bool) -> [Node]
    func healthCheck()
    func nodesUpdate()
}
