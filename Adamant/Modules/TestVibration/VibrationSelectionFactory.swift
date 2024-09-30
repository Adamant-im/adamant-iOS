//
//  VibrationSelectionFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

struct VibrationSelectionFactory {
    private let parent: Assembler
    private let assemblies = [VibrationSelectionAssembly()]
    
    init(parent: Assembler) {
        self.parent = parent
    }
    
    @MainActor
    func makeViewController() -> UIViewController {
        let assembler = Assembler(assemblies, parent: parent)
        let viewModel = { assembler.resolver.resolve(VibrationSelectionViewModel.self)! }
        return UIHostingController(rootView: VibrationSelectionView(viewModel: viewModel))
    }
}

private struct VibrationSelectionAssembly: Assembly {
    func assemble(container: Container) {
        container.register(VibrationSelectionViewModel.self) {
            VibrationSelectionViewModel(
                vibroService: $0.resolve(VibroService.self)!
            )
        }.inObjectScope(.transient)
    }
}
