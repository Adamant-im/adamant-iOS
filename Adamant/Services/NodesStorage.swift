//
//  NodesStorage.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import Combine

final class NodesStorage: NodesStorageProtocol {
    @Atomic private var items: ObservableValue<[NodeWithGroup]>
    
    var nodesWithGroupsPublisher: AnyObservable<[NodeWithGroup]> {
        items.removeDuplicates().eraseToAnyPublisher()
    }
    
    private var subscription: AnyCancellable?
    private let securedStore: SecuredStore
    
    func getNodesPublisher(group: NodeGroup) -> AnyObservable<[Node]> {
        items
            .map { $0.filter { $0.group == group }.map { $0.node } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func addNode(_ node: Node, group: NodeGroup) {
        items.wrappedValue.append(.init(group: group, node: node))
    }
    
    func removeNode(id: UUID) {
        $items.mutate { items in
            guard let index = items.wrappedValue.getIndex(id: id) else { return }
            items.wrappedValue.remove(at: index)
        }
    }
    
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
    ) {
        $items.mutate { items in
            guard
                let index = items.wrappedValue.getIndex(id: id),
                var node = items.wrappedValue[safe: index]?.node
            else { return }
            
            scheme.map { node.scheme = $0 }
            host.map { node.host = $0 }
            wsEnabled.map { node.wsEnabled = $0 }
            port.map { node.port = $0 }
            wsPort.map { node.wsPort = $0 }
            version.map { node.version = $0 }
            height.map { node.height = $0 }
            ping.map { node.ping = $0 }
            connectionStatus.map { node.connectionStatus = $0 }
            
            if let isEnabled = isEnabled {
                node.isEnabled = isEnabled
                
                if !isEnabled {
                    node.connectionStatus = nil
                }
            }
            
            items.wrappedValue[index].node = node
        }
    }
    
    func resetNodes(group: NodeGroup) {
        $items.mutate { items in
            items.wrappedValue = items.wrappedValue.filter {
                $0.group != group
            }
            
            items.wrappedValue += Self.defaultItems(group: group)
        }
    }
    
    func haveActiveNode(in group: CommonKit.NodeGroup) -> Bool {
        let nodes = items.wrappedValue.filter { $0.group == group }.map { $0.node }
        let node = nodes.first(where: { $0.connectionStatus == .allowed && $0.isEnabled })
        return node != nil
    }
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        var nodes = securedStore.get(StoreKey.NodesStorage.nodes) ?? Self.defaultItems
        let nodesToAdd = Self.defaultItems.filter { defaultNode in
            !nodes.contains { $0.node.host == defaultNode.node.host }
        }
        nodes.append(contentsOf: nodesToAdd)
        
        _items = .init(wrappedValue: .init(
            wrappedValue: nodes
        ))
        
        subscription = items.removeDuplicates().sink { [weak self] in
            guard let self = self, subscription != nil else { return }
            saveNodes(nodes: $0)
        }
    }
}

private extension NodesStorage {
    static func defaultItems(group: NodeGroup) -> [NodeWithGroup] {
        switch group {
        case .btc:
            return BtcWalletService.nodes.map { .init(group: .btc, node: $0) }
        case .eth:
            return EthWalletService.nodes.map { .init(group: .eth, node: $0) }
        case .klyNode:
            return KlyWalletService.nodes.map { .init(group: .klyNode, node: $0) }
        case .klyService:
            return KlyWalletService.serviceNodes.map { .init(group: .klyService, node: $0) }
        case .doge:
            return DogeWalletService.nodes.map { .init(group: .doge, node: $0) }
        case .dash:
            return DashWalletService.nodes.map { .init(group: .dash, node: $0) }
        case .adm:
            return AdmWalletService.nodes.map { .init(group: .adm, node: $0) }
        case .ipfs:
            return IPFSApiService.nodes.map { .init(group: .ipfs, node: $0) }
        }
    }
    
    static var defaultItems: [NodeWithGroup] {
        NodeGroup.allCases.flatMap { Self.defaultItems(group: $0) }
    }
    
    func saveNodes(nodes: [NodeWithGroup]) {
        securedStore.set(nodes, for: StoreKey.NodesStorage.nodes)
    }
}

private extension Array where Element == NodeWithGroup {
    func getNode(id: UUID) -> Node? {
        first { $0.node.id == id }?.node
    }
    
    func getIndex(id: UUID) -> Int? {
        firstIndex { $0.node.id == id }
    }
}
