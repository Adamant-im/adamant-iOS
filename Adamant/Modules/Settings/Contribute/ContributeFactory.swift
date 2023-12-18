//
//  ContributeFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

struct ContributeFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([ContributeAssembly()], parent: parent)
    }
    
    func makeViewController() -> UIViewController {
        UIHostingController(
            rootView: ContributeView(
                viewModel: assembler.resolve(ContributeViewModel.self)!
            )
        )
    }
}

private struct ContributeAssembly: Assembly {
    func assemble(container: Container) {
        container.register(ContributeViewModel.self) {
            ContributeViewModel(
                crashliticsService: $0.resolve(CrashlyticsService.self)!
            )
        }.inObjectScope(.weak)
    }
}
