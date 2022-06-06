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
        /// Raised when best node changed
        static let bestNodeChanged = Notification.Name("adamant.nodesSource.bestNodeChanged")
        
        private init() {}
    }
}

extension AdamantUserInfoKey {
    struct nodesSource {
        /// New best node
        static let bestNode = "adamant.nodesSource.bestNode"
        
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

protocol NodesSource: AnyObject {
    var nodes: [Node] { get set }
    var defaultNodes: [Node] { get }
    var bestNode: Node { get }
    
    func getSocketNewNode() -> Node
    
    func saveNodes()
    func migrate()
    func bestNodeIsUnavailable()
}
