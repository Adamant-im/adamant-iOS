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
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([VibrationSelectionAssembly()], parent: parent)
    }
    
    func makeViewController() -> UIViewController {
        UIHostingController(
            rootView: VibrationSelectionView(
                viewModel: assembler.resolve(VibrationSelectionViewModel.self)!
            )
        )
    }
}

private struct VibrationSelectionAssembly: Assembly {
    func assemble(container: Container) {
        container.register(VibrationSelectionViewModel.self) {
            VibrationSelectionViewModel(
                vibroService: $0.resolve(VibroService.self)!
            )
        }.inObjectScope(.weak)
    }
}
