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
    func getPreferredNode(needWS: Bool) -> Node?
    func healthCheck()
    func nodesChanged()
}
