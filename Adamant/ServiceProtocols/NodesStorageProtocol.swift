//
//  NodesStorageProtocol.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation

// MARK: - SecuredStore keys
extension StoreKey {
    enum NodesStorage {
        static let nodes = "nodesStorage.nodes"
    }
}

protocol NodesStorageProtocol {
    var nodesWithGroupsPublisher: AnyObservable<[NodeWithGroup]> { get }
    
    func getNodesPublisher(group: NodeGroup) -> AnyObservable<[Node]>
    func addNode(_ node: Node, group: NodeGroup)
    func resetNodes(group: NodeGroup)
    func removeNode(id: UUID)
    func haveActiveNode(in group: NodeGroup) -> Bool
    func updateNode(id: UUID, mutate: (inout Node) -> Void)
}
