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
    private let processedGroups: Set<NodeGroup>
    private let apiServices: ApiServices
    private var subscriptions = Set<AnyCancellable>()
    
    nonisolated init(
        mapper: CoinsNodesListMapper,
        nodesStorage: NodesStorageProtocol,
        nodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol,
        processedGroups: Set<NodeGroup>,
        apiServices: ApiServices
    ) {
        self.mapper = mapper
        self.nodesStorage = nodesStorage
        self.nodesAdditionalParamsStorage = nodesAdditionalParamsStorage
        self.processedGroups = processedGroups
        self.apiServices = apiServices
        Task { @MainActor in setup() }
    }
    
    func setIsEnabled(id: UUID, value: Bool) {
        nodesStorage.updateNodeParams(id: id, isEnabled: value)
    }
    
    func reset() {
        processedGroups.forEach {
            nodesStorage.resetNodes(group: $0)
        }
    }
}

private extension CoinsNodesListViewModel {
    func setup() {
        state.fastestNodeMode = processedGroups
            .map { nodesAdditionalParamsStorage.isFastestNodeMode(group: $0) }
            .reduce(into: true) { $0 = $0 && $1 }
        
        $state
            .map(\.fastestNodeMode)
            .removeDuplicates()
            .sink { [weak self] in self?.saveFastestNodeMode($0) }
            .store(in: &subscriptions)
        
        guard let someGroup = processedGroups.first else { return }
        
        nodesStorage.nodesWithGroupsPublisher
            .combineLatest(nodesAdditionalParamsStorage.fastestNodeMode(group: someGroup))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.updateSections(items: $0.0) }
            .store(in: &subscriptions)
        
        Timer
            .publish(every: someGroup.onScreenUpdateInterval, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in self?.healthCheck() }
            .store(in: &subscriptions)
        
        healthCheck()
    }
    
    func updateSections(items: [NodeWithGroup]) {
        state.sections = mapper.map(
            items: items,
            restNodeIds: processedGroups.flatMap {
                apiServices.getApiService(group: $0).preferredNodeIds
            }
        )
    }
    
    func saveFastestNodeMode(_ value: Bool) {
        nodesAdditionalParamsStorage.setFastestNodeMode(
            groups: processedGroups,
            value: value
        )
    }
    
    func healthCheck() {
        processedGroups.forEach {
            apiServices.getApiService(group: $0).healthCheck()
        }
    }
}
