//
//  CoinsNodesListViewModel.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import Combine
import CommonKit

@MainActor
final class CoinsNodesListViewModel: ObservableObject {
    @Published var state: CoinsNodesListState = .default
    
    private let mapper: CoinsNodesListMapper
    private let nodesStorage: NodesStorageProtocol
    private let nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol
    private let processedGroups: [NodeGroup]
    private let apiServiceCompose: ApiServiceComposeProtocol
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        mapper: CoinsNodesListMapper,
        nodesStorage: NodesStorageProtocol,
        nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol,
        processedGroups: [NodeGroup],
        apiServiceCompose: ApiServiceComposeProtocol
    ) {
        self.mapper = mapper
        self.nodesStorage = nodesStorage
        self.nodesAdditionalParamsStorage = nodesAdditionalParamsStorage
        self.processedGroups = processedGroups
        self.apiServiceCompose = apiServiceCompose
        setup()
    }
    
    func setIsEnabled(id: UUID, group: NodeGroup, value: Bool) {
        nodesStorage.updateNode(id: id, group: group) { $0.isEnabled = value }
    }
    
    func reset() {
        nodesStorage.resetNodes(.init(processedGroups))
    }
}

private extension CoinsNodesListViewModel {
    func setup() {
        state.sections = processedGroups.compactMap {
            guard let info = apiServiceCompose.get($0)?.nodesInfo else { return nil }
            return mapper.map(group: $0, nodesInfo: info)
        }
        
        processedGroups.forEach { group in
            apiServiceCompose.get(group)?
                .nodesInfoPublisher
                .sink { [weak self] in self?.updateSections(group: group, nodesInfo: $0) }
                .store(in: &subscriptions)
        }
        
        if let someGroup = processedGroups.first {
            state.fastestNodeMode = nodesAdditionalParamsStorage.isFastestNodeMode(group: someGroup)
            
            Timer
                .publish(every: someGroup.onScreenUpdateInterval, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in self?.healthCheck() }
                .store(in: &subscriptions)
        }
        
        setStateObservation()
        healthCheck()
    }
    
    func updateSections(group: NodeGroup, nodesInfo: NodesListInfo) {
        guard let index = state.sections.firstIndex(where: { $0.id == group }) else { return }
        state.sections[index] = mapper.map(group: group, nodesInfo: nodesInfo)
    }
    
    func saveFastestNodeMode(_ value: Bool) {
        nodesAdditionalParamsStorage.setFastestNodeMode(
            groups: .init(processedGroups),
            value: value
        )
    }
    
    func healthCheck() {
        processedGroups.forEach {
            apiServiceCompose.get($0)?.healthCheck()
        }
    }
    
    func setStateObservation() {
        $state
            .map(\.fastestNodeMode)
            .removeDuplicates()
            .sink { [weak self] in self?.saveFastestNodeMode($0) }
            .store(in: &subscriptions)
        
    }
}
