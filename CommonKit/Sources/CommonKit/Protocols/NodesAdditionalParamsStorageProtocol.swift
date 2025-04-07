//
//  NodesAdditionalParamsStorageProtocol.swift
//  Adamant
//
//  Created by Andrew G on 18.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

// MARK: - SecureStore keys
extension StoreKey {
    public enum NodesAdditionalParamsStorage {
        public static let fastestNodeMode = "nodesAdditionalParamsStorage.fastestNodeMode"
    }
}

public protocol NodesAdditionalParamsStorageProtocol {
    func isFastestNodeMode(group: NodeGroup) -> Bool
    func fastestNodeMode(group: NodeGroup) -> AnyObservable<Bool>
    func setFastestNodeMode(groups: Set<NodeGroup>, value: Bool)
    func setFastestNodeMode(group: NodeGroup, value: Bool)
}
