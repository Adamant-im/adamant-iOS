//
//  NodesStorageProtocol.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

// MARK: - SecuredStore keys
public extension StoreKey {
    enum NodesStorage {
        public static let nodes = "nodesStorage.nodes"
    }
}

public protocol NodesStorageProtocol: Sendable {
    var nodesPublisher: AnyObservable<[NodeGroup: [Node]]> { get }
    
    func getNodesPublisher(group: NodeGroup) -> AnyObservable<[Node]>
    func addNode(_ node: Node, group: NodeGroup)
    func resetNodes(_ groups: Set<NodeGroup>)
    func removeNode(id: UUID, group: NodeGroup)
    func updateNode(id: UUID, group: NodeGroup, mutate: (inout Node) -> Void)
}
