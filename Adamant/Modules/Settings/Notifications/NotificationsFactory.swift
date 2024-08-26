//
//  NotificationsFactory.swift
//  Adamant
//
//  Created by Yana Silosieva on 05.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

struct NotificationsFactory {
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([NotificationsAssembly()], parent: parent)
    }
    
    @MainActor
    func makeViewController(screensFactory: ScreensFactory) -> UIViewController {
        let viewModel = assembler.resolve(NotificationsViewModel.self)!
        
        let view = NotificationsView(
            viewModel: viewModel,
            screensFactory: screensFactory
        )
        
        return UIHostingController(
            rootView: view
        )
    }
}

private struct NotificationsAssembly: Assembly {
    func assemble(container: Container) {
        container.register(NotificationsViewModel.self) { r in
            NotificationsViewModel(
                dialogService: r.resolve(DialogService.self)!,
                notificationsService: r.resolve(NotificationsService.self)!
            )
        }.inObjectScope(.weak)
    }
}
