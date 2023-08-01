//
//  NodesListFactory.swift
//  Adamant
//
//  Created by Andrey Golubenko on 01.08.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

struct NodesListFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([NodesListAssembly()], parent: parent)
    }
    
    func makeViewController() -> UIViewController {
        let viewModel = assembler.resolver.resolve(NodesListViewModel.self)!
        let view = NodesListView(viewModel: viewModel)
        return UIHostingController(rootView: view)
    }
}

private struct NodesListAssembly: Assembly {
    func assemble(container: Container) {
        container.register(NodesListViewModel.self) {
            NodesListViewModel(
                coinsHealthCheckService: $0.resolve(CoinsHealthCheckService.self)!
            )
        }.inObjectScope(.transient)
    }
}
