//
//  PKGeneratorFactory.swift
//  Adamant
//
//  Created by Andrew G on 28.11.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

struct PKGeneratorFactory {
    private let parent: Assembler
    private let assemblies = [PKGeneratorAssembly()]
    
    init(parent: Assembler) {
        self.parent = parent
    }
    
    func makeViewController() -> UIViewController {
        let assembler = Assembler(assemblies, parent: parent)
        let viewModel = { assembler.resolver.resolve(PKGeneratorViewModel.self)! }
        return UIHostingController(rootView: PKGeneratorView(viewModel: viewModel))
    }
}

private struct PKGeneratorAssembly: Assembly {
    func assemble(container: Container) {
        container.register(PKGeneratorViewModel.self) {
            .init(
                dialogService: $0.resolve(DialogService.self)!,
                walletServiceCompose: $0.resolve(PublicWalletServiceCompose.self)!
            )
        }.inObjectScope(.transient)
    }
}
