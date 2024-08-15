//
//  PinpadFactory.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 15.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Swinject
import SwiftUI
import FilesStorageKit

struct PinpadFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([PinpadAssembly()], parent: parent)
    }
    
    func makeViewController(successAction: (() -> Void)?) -> UIViewController {
        let vc = PinpadWrapperViewController(
            viewModel: assembler.resolve(PinpadWrapperViewModel.self)!
        )
        vc.successAction = successAction
        return vc
    }
}

private struct PinpadAssembly: Assembly {
    func assemble(container: Container) {
        container.register(PinpadWrapperViewModel.self) {
            PinpadWrapperViewModel(
                accountService: $0.resolve(AccountService.self)!,
                localAuth: $0.resolve(LocalAuthentication.self)!
            )
        }.inObjectScope(.weak)
    }
}
