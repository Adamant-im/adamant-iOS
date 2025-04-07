//
//  ExtensionsApiFactory.swift
//
//
//  Created by Andrew G on 08.08.2024.
//

import Combine

public struct ExtensionsApiFactory {
    public let core: AdamantCore
    public let SecureStore: SecureStore

    public init(core: AdamantCore, SecureStore: SecureStore) {
        self.core = core
        self.SecureStore = SecureStore
    }

    public func make() -> ExtensionsApi {
        .init(
            apiService: AdamantApiService(
                healthCheckWrapper: .init(
                    service: AdamantApiCore(apiCore: APICore()),
                    nodesStorage: NodesStorage(
                        SecureStore: SecureStore,
                        nodesMergingService: NodesMergingService(),
                        defaultNodes: { _ in .init() }
                    ),
                    nodesAdditionalParamsStorage: NodesAdditionalParamsStorage(
                        SecureStore: SecureStore
                    ),
                    isActive: false,
                    params: .init(
                        group: .adm,
                        name: "ADM",
                        normalUpdateInterval: .infinity,
                        crucialUpdateInterval: .infinity,
                        minNodeVersion: nil,
                        nodeHeightEpsilon: .zero
                    ),
                    connection: Just(true).eraseToAnyPublisher()
                ),
                adamantCore: core
            )
        )
    }
}
