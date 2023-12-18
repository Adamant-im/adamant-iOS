//
//  CoinsNodesListFactory.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import SwiftUI
import CommonKit

enum CoinsNodesListContext {
    case login
    case menu
}

struct CoinsNodesListFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([CoinsNodesListAssembly()], parent: parent)
    }
    
    func makeViewController(context: CoinsNodesListContext) -> UIViewController {
        let viewModel = assembler.resolve(CoinsNodesListViewModel.self)!
        let view = CoinsNodesListView(viewModel: viewModel)
        
        switch context {
        case .login:
            return SelfRemovableHostingController(rootView: view)
        case .menu:
            return UIHostingController(rootView: view)
        }
    }
}

private struct CoinsNodesListAssembly: Assembly {
    func assemble(container: Container) {
        container.register(CoinsNodesListViewModel.self) {
            let processedGroups = Set(NodeGroup.allCases).subtracting([.adm])
            
            return .init(
                mapper: .init(processedGroups: processedGroups),
                nodesStorage: $0.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: $0.resolve(
                    NodesAdditionalParamsStorageProtocol.self
                )!,
                processedGroups: processedGroups,
                apiServices: .init(
                    btc: $0.resolve(BtcApiService.self)!,
                    eth: $0.resolve(EthApiService.self)!,
                    lskNode: $0.resolve(LskNodeApiService.self)!,
                    lskService: $0.resolve(LskServiceApiService.self)!,
                    doge: $0.resolve(DogeApiService.self)!,
                    dash: $0.resolve(DashApiService.self)!,
                    adm: $0.resolve(ApiService.self)!
                )
            )
        }.inObjectScope(.weak)
    }
}
