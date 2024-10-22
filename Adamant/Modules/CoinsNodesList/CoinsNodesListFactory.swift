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

@MainActor
struct CoinsNodesListFactory {
    private let parent: Assembler
    private let assemblies = [CoinsNodesListAssembly()]
    
    init(parent: Assembler) {
        self.parent = parent
    }
    
    @MainActor
    func makeViewController(context: CoinsNodesListContext) -> UIViewController {
        let assembler = Assembler(assemblies, parent: parent)
        let viewModel = { assembler.resolver.resolve(CoinsNodesListViewModel.self)! }
        let view = CoinsNodesListView(viewModel: viewModel)
        
        switch context {
        case .login:
            return SelfRemovableHostingController(rootView: view)
        case .menu:
            return UIHostingController(rootView: view)
        }
    }
}

private struct CoinsNodesListAssembly: MainThreadAssembly {
    func assembleOnMainThread(container: Container) {
        container.register(CoinsNodesListViewModel.self) {
            let processedGroups = NodeGroup.allCases.filter { $0 != .adm }
            
            return .init(
                mapper: .init(processedGroups: processedGroups),
                nodesStorage: $0.resolve(NodesStorageProtocol.self)!,
                nodesAdditionalParamsStorage: $0.resolve(
                    NodesAdditionalParamsStorageProtocol.self
                )!,
                processedGroups: processedGroups,
                apiServiceCompose: $0.resolve(
                    ApiServiceComposeProtocol.self
                )!
            )
        }.inObjectScope(.transient)
    }
}
