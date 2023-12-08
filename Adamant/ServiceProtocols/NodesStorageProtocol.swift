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
    func isHaveActiveNode(in group: NodeGroup) -> Bool
    
    func updateNode(
        id: UUID,
        scheme: CommonKit.Node.URLScheme?,
        host: String?,
        isEnabled: Bool?,
        wsEnabled: Bool?,
        port: Int??,
        wsPort: Int??,
        version: String??,
        height: Int??,
        ping: TimeInterval??,
        connectionStatus: CommonKit.Node.ConnectionStatus??
    )
}

extension NodesStorageProtocol {
    func updateNodeStatus(id: UUID, statusInfo: NodeStatusInfo?) {
        updateNodeParams(
            id: id,
            wsEnabled: .some(statusInfo?.wsEnabled ?? false),
            wsPort: .some(statusInfo?.wsPort),
            version: .some(statusInfo?.version),
            height: .some(statusInfo?.height),
            ping: .some(statusInfo?.ping)
        )
    }
    
    func updateNodeParams(
        id: UUID,
        scheme: CommonKit.Node.URLScheme? = nil,
        host: String? = nil,
        isEnabled: Bool? = nil,
        wsEnabled: Bool? = nil,
        port: Int?? = nil,
        wsPort: Int?? = nil,
        version: String?? = nil,
        height: Int?? = nil,
        ping: TimeInterval?? = nil,
        connectionStatus: CommonKit.Node.ConnectionStatus?? = nil
    ) {
        updateNode(
            id: id,
            scheme: scheme,
            host: host,
            isEnabled: isEnabled,
            wsEnabled: wsEnabled,
            port: port,
            wsPort: wsPort,
            version: version,
            height: height,
            ping: ping,
            connectionStatus: connectionStatus
        )
    }
}
