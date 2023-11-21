//
//  NodesAdditionalParamsStorageProtocol.swift
//  Adamant
//
//  Created by Andrew G on 18.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

// MARK: - SecuredStore keys
extension StoreKey {
    enum NodesAdditionalParamsStorage {
        static let fastestNodeMode = "nodesAdditionalParamsStorage.fastestNodeMode"
    }
}

protocol NodesAdditionalParamsStorageProtocol {
    func isFastestNodeMode(group: NodeGroup) -> Bool
    func fastestNodeMode(group: NodeGroup) -> AnyObservable<Bool>
    func setFastestNodeMode(groups: Set<NodeGroup>, value: Bool)
    func setFastestNodeMode(group: NodeGroup, value: Bool)
}
