//
//  NodesStorage.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

public final class NodesStorage: NodesStorageProtocol {
    @Atomic private var items: ObservableValue<[NodeGroup: [Node]]> = .init(wrappedValue: .init())
    
    public var nodesPublisher: AnyObservable<[NodeGroup: [Node]]> {
        items
            .map { $0.mapValues { $0.filter { !$0.isHidden } } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var subscription: AnyCancellable?
    private let securedStore: SecuredStore
    private let nodesMergingService: NodesMergingService
    private let defaultNodes: [NodeGroup: [Node]]
    
    public func getNodesPublisher(group: NodeGroup) -> AnyObservable<[Node]> {
        nodesPublisher
            .map { $0[group] ?? .init() }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    public func addNode(_ node: Node, group: NodeGroup) {
        $items.mutate { items in
            if items.wrappedValue[group] == nil {
                items.wrappedValue[group] = [node]
            } else {
                items.wrappedValue[group]?.append(node)
            }
        }
    }
    
    public func removeNode(id: UUID, group: NodeGroup) {
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
    
    public func updateNode(id: UUID, group: NodeGroup, mutate: (inout Node) -> Void) {
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
    
    public func resetNodes(group: NodeGroup) {
        items.wrappedValue[group] = defaultNodes[group] ?? .init()
    }
    
    public init(
        securedStore: SecuredStore,
        nodesMergingService: NodesMergingService,
        defaultNodes: [NodeGroup: [Node]]
    ) {
        self.securedStore = securedStore
        self.nodesMergingService = nodesMergingService
        self.defaultNodes = defaultNodes
        setupNodes()
    }
}

private extension NodesStorage {
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
            defaultNodes: defaultNodes
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
