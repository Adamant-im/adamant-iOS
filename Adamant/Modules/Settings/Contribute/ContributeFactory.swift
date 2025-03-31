//
//  ContributeFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import Swinject

@MainActor
struct ContributeFactory {
    private let parent: Assembler
    private let assemblies = [ContributeAssembly()]

    init(parent: Assembler) {
        self.parent = parent
    }

    func makeViewController() -> UIViewController {
        let assembler = Assembler(assemblies, parent: parent)
        let viewModel = { assembler.resolver.resolve(ContributeViewModel.self)! }
        return UIHostingController(rootView: ContributeView(viewModel: viewModel))
    }
}

private struct ContributeAssembly: MainThreadAssembly {
    func assembleOnMainThread(container: Container) {
        container.register(ContributeViewModel.self) {
            ContributeViewModel(
                crashliticsService: $0.resolve(CrashlyticsService.self)!
            )
        }.inObjectScope(.transient)
    }
}
