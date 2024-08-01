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
    @Atomic private var items: ObservableValue<[NodeGroup: [Node]]> = .init(wrappedValue: .init())
    
    var nodesPublisher: AnyObservable<[NodeGroup: [Node]]> {
        items
            .map { $0.mapValues { $0.filter { !$0.isHidden } } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var subscription: AnyCancellable?
    private let securedStore: SecuredStore
    private let nodesMergingService: NodesMergingService
    
    func getNodesPublisher(group: NodeGroup) -> AnyObservable<[Node]> {
        nodesPublisher
            .map { $0[group] ?? .init() }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func addNode(_ node: Node, group: NodeGroup) {
        $items.mutate { items in
            if items.wrappedValue[group] == nil {
                items.wrappedValue[group] = [node]
            } else {
                items.wrappedValue[group]?.append(node)
            }
        }
    }
    
    func removeNode(id: UUID, group: NodeGroup) {
        $items.mutate { items in
            guard
                let index = items.wrappedValue[group]?.firstIndex(where: { $0.id == id })
            else { return }
            
            switch items.wrappedValue[group]?[safe: index]?.type {
            case .default:
                items.wrappedValue[group]?[index].type = .default(isHidden: true)
            case .custom:
                items.wrappedValue[group]?.remove(at: index)
            case .none:
                break
            }
        }
    }
    
    func updateNode(id: UUID, group: NodeGroup, mutate: (inout Node) -> Void) {
        $items.mutate { items in
            guard
                let index = items.wrappedValue[group]?.firstIndex(where: { $0.id == id }),
                var node = items.wrappedValue[group]?[safe: index]
            else { return }
            
            let previousValue = node
            mutate(&node)
            
            if !node.isEnabled {
                node.connectionStatus = nil
            }
            
            switch node.type {
            case .default:
                guard !previousValue.isSame(node) else { break }
                node.type = .custom
            case .custom:
                break
            }
            
            guard node != previousValue else { return }
            items.wrappedValue[group]?[index] = node
        }
    }
    
    func resetNodes(group: NodeGroup) {
        items.wrappedValue[group] = Self.defaultItems(group: group)
    }
    
    init(securedStore: SecuredStore, nodesMergingService: NodesMergingService) {
        self.securedStore = securedStore
        self.nodesMergingService = nodesMergingService
        setupNodes()
    }
}

private extension NodesStorage {
    static func defaultItems(group: NodeGroup) -> [Node] {
        switch group {
        case .btc:
            return BtcWalletService.nodes
        case .eth:
            return EthWalletService.nodes
        case .klyNode:
            return KlyWalletService.nodes
        case .klyService:
            return KlyWalletService.serviceNodes
        case .doge:
            return DogeWalletService.nodes
        case .dash:
            return DashWalletService.nodes
        case .adm:
            return AdmWalletService.nodes
        }
    }
    
    static var defaultItems: [NodeGroup: [Node]] {
        .init(
            uniqueKeysWithValues: NodeGroup.allCases.map {
                ($0, defaultItems(group: $0))
            }
        )
    }
    
    func saveNodes(nodes: [NodeGroup: [Node]]) {
        let nodesDto = nodes.mapValues { $0.map { $0.mapToDto() } }
        securedStore.set(nodesDto, for: StoreKey.NodesStorage.nodes)
    }
    
    func setupNodes() {
        let dto: SafeDecodingDictionary<
            NodeGroup,
            SafeDecodingArray<NodeKeychainDTO>
        >? = securedStore.get(StoreKey.NodesStorage.nodes)
        
        let savedNodes = dto?.values.mapValues { $0.map { $0.mapToModel() } }
            ?? migrateOldNodesData()
            ?? .init()
        
        items.wrappedValue = nodesMergingService.merge(
            savedNodes: savedNodes,
            defaultNodes: Self.defaultItems
        )
        
        subscription = items.removeDuplicates().sink { [weak self] in
            guard let self = self else { return }
            saveNodes(nodes: $0)
        }
    }
    
    func migrateOldNodesData() -> [NodeGroup: [Node]]? {
        let dto: SafeDecodingArray<OldNodeKeychainDTO>? = securedStore.get(StoreKey.NodesStorage.nodes)
        guard let dto = dto else { return nil }
        var result: [NodeGroup: [Node]] = [:]
        
        dto.forEach {
            if result[$0.group] == nil {
                result[$0.group] = []
            }
            
            result[$0.group]?.append($0.node.mapToModernDto().mapToModel())
        }
        
        return result
    }
}

private extension Node {
    var isHidden: Bool {
        switch type {
        case let .default(isHidden):
            return isHidden
        case .custom:
            return false
        }
    }
}
