//
//  SettingSelectionFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

@MainActor
struct SettingSelectionFactory {
    private let parent: Assembler
    private let assemblies = [VibrationSelectionAssembly()]
    
    init(parent: Assembler) {
        self.parent = parent
    }
    
    @MainActor
    func makeViewController(onSettingsSelect: @escaping (SettingsView.SettingsType) -> Void) -> UIViewController {
        let assembler = Assembler(assemblies, parent: parent)
        let viewModel = { assembler.resolver.resolve(VibrationSelectionViewModel.self)! }
        return UIHostingController(rootView: SettingsView(viewModel: viewModel, onSettingsSelect: onSettingsSelect))
    }
}

private struct VibrationSelectionAssembly: MainThreadAssembly {
    func assembleOnMainThread(container: Container) {
        container.register(VibrationSelectionViewModel.self) {
            VibrationSelectionViewModel(
                vibroService: $0.resolve(VibroService.self)!
            )
        }.inObjectScope(.transient)
    }
}
