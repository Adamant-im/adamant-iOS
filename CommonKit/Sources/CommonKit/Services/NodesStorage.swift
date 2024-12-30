//
//  NodesStorage.swift
//  Adamant
//
//  Created by Andrew G on 30.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

public final class NodesStorage: NodesStorageProtocol, @unchecked Sendable {
    public typealias DefaultNodesGetter = @Sendable (Set<NodeGroup>) -> [NodeGroup: [Node]]
    
    @Atomic private var items: ObservableValue<[NodeGroup: [Node]]>
    
    public var nodesPublisher: AnyObservable<[NodeGroup: [Node]]> {
        items
            .map { $0.mapValues { $0.filter { !$0.isHidden } } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var subscription: AnyCancellable?
    private let securedStore: SecuredStore
    private let defaultNodes: DefaultNodesGetter
    
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
                node.height = nil
                node.ping = nil
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
    
    public func resetNodes(_ groups: Set<NodeGroup>) {
        let defaultNodes = defaultNodes(groups)
        
        $items.mutate { items in
            for group in groups {
                items.wrappedValue[group] = defaultNodes[group] ?? .init()
            }
        }
    }
    
    public init(
        securedStore: SecuredStore,
        nodesMergingService: NodesMergingServiceProtocol,
        defaultNodes: @escaping DefaultNodesGetter
    ) {
        self.securedStore = securedStore
        self.defaultNodes = defaultNodes
        
        let dto: NodesKeychainDTO? = securedStore.get(StoreKey.NodesStorage.nodes)
        
        let savedNodes = dto?.data.values.mapValues { $0.map { $0.mapToModel() } }
            ?? migrateOldNodesData(securedStore: securedStore)
            ?? .init()
        
        _items = .init(.init(wrappedValue: nodesMergingService.merge(
            savedNodes: savedNodes,
            defaultNodes: defaultNodes(.init(NodeGroup.allCases))
        )))
        
        subscription = items.removeDuplicates().sink { [weak self] in
            guard let self = self else { return }
            saveNodes(nodes: $0)
        }
        
        // Applying empty mutations, so post-mutation code in `func updateNode` will be executed
        for (group, nodes) in items.wrappedValue {
            for node in nodes {
                updateNode(id: node.id, group: group) { _ in }
            }
        }
    }
}

private extension NodesStorage {
    func saveNodes(nodes: [NodeGroup: [Node]]) {
        let nodesDto = NodesKeychainDTO(nodes.mapValues { $0.map { $0.mapToDto() } })
        securedStore.set(nodesDto, for: StoreKey.NodesStorage.nodes)
    }
}

private func migrateOldNodesData(securedStore: SecuredStore) -> [NodeGroup: [Node]]? {
    let dto: SafeDecodingArray<OldNodeKeychainDTO>? = securedStore.get(StoreKey.NodesStorage.nodes)
    guard let dto = dto else { return nil }
    var result: [NodeGroup: [Node]] = [:]
    
    dto.forEach {
        if result[$0.group] == nil {
            result[$0.group] = []
        }
        
        result[$0.group]?.append($0.node.mapToModernDto(group: $0.group).mapToModel())
    }
    
    return result
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
