//
//  InfoServiceAssembly.swift
//  Adamant
//
//  Created by Andrew G on 24.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Swinject
import CommonKit

struct InfoServiceAssembly: Assembly {
    func assemble(container: Container) {
        container.register(InfoServiceProtocol.self) { r in
            InfoService(
                securedStore: r.resolve(SecuredStore.self)!,
                walletServiceCompose: r.resolve(WalletServiceCompose.self)!,
                api: r.resolve(InfoServiceApiServiceProtocol.self)!
            )
        }.inObjectScope(.container)
        
        container.register(InfoServiceApiServiceProtocol.self) { r in
            InfoServiceApiService(core: .init(
                service: .init(
                    apiCore: r.resolve(APICoreProtocol.self)!,
                    mapper: r.resolve(InfoServiceMapperProtocol.self)!),
                nodesStorage: r.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: r.resolve(NodesAdditionalParamsStorageProtocol.self)!,
                isActive: true,
                params: NodeGroup.infoService.blockchainHealthCheckParams,
                connection: r.resolve(ReachabilityMonitor.self)!.connectionPublisher
            ))
        }.inObjectScope(.transient)
        
        container.register(InfoServiceMapperProtocol.self) { _ in
            InfoServiceMapper()
        }.inObjectScope(.transient)
    }
}
