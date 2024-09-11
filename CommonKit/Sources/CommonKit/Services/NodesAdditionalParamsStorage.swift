//
//  NodesAdditionalParamsStorage.swift
//  Adamant
//
//  Created by Andrew G on 18.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

public final class NodesAdditionalParamsStorage: NodesAdditionalParamsStorageProtocol {
    @Atomic private var fastestNodeModeValues: ObservableValue<[NodeGroup: Bool]>
    
    private let securedStore: SecuredStore
    private var subscription: AnyCancellable?
    
    public func isFastestNodeMode(group: NodeGroup) -> Bool {
        fastestNodeModeValues.wrappedValue[group] ?? group.defaultFastestNodeMode
    }
    
    public func fastestNodeMode(group: NodeGroup) -> AnyObservable<Bool> {
        fastestNodeModeValues
            .map { $0[group] ?? group.defaultFastestNodeMode }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    public func setFastestNodeMode(groups: Set<NodeGroup>, value: Bool) {
        $fastestNodeModeValues.mutate { dict in
            groups.forEach {
                dict.wrappedValue[$0] = value
            }
        }
    }
    
    public func setFastestNodeMode(group: NodeGroup, value: Bool) {
        fastestNodeModeValues.wrappedValue[group] = value
    }
    
    public init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        _fastestNodeModeValues = .init(wrappedValue: .init(
            wrappedValue: securedStore.get(
                StoreKey.NodesAdditionalParamsStorage.fastestNodeMode
            ) ?? [:]
        ))
        
        subscription = fastestNodeModeValues.removeDuplicates().sink { [weak self] in
            guard let self = self, subscription != nil else { return }
            saveFastestNodeMode($0)
        }
    }
}

private extension NodesAdditionalParamsStorage {
    func saveFastestNodeMode(_ dict: [NodeGroup: Bool]) {
        securedStore.set(dict, for: StoreKey.NodesAdditionalParamsStorage.fastestNodeMode)
    }
}
