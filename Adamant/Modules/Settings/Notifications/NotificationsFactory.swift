//
//  NotificationsFactory.swift
//  Adamant
//
//  Created by Yana Silosieva on 05.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

@MainActor
struct NotificationsFactory {
    private let parent: Assembler
    private let assemblies = [NotificationsAssembly()]
    
    init(parent: Assembler) {
        self.parent = parent
    }
    
    @MainActor
    func makeViewController(screensFactory: ScreensFactory) -> UIViewController {
        let assembler = Assembler(assemblies, parent: parent)
        let viewModel = { assembler.resolver.resolve(NotificationsViewModel.self)! }
        
        let baseSoundsFactory = NotificationSoundsFactory(parent: assembler)
        let reactionSoundsFactory = NotificationSoundsFactory(parent: assembler)
        
        let baseSoundsView = { baseSoundsFactory.makeView(target: .baseMessage).eraseToAnyView() }
        let reactionSoundsView = { reactionSoundsFactory.makeView(target: .reaction).eraseToAnyView() }
        
        let view = NotificationsView(
            viewModel: viewModel,
            baseSoundsView: baseSoundsView,
            reactionSoundsView: reactionSoundsView,
            screensFactory: screensFactory
        )
        
        return UIHostingController(
            rootView: view
        )
    }
}

private struct NotificationsAssembly: MainThreadAssembly {
    func assembleOnMainThread(container: Container) {
        container.register(NotificationsViewModel.self) { r in
            NotificationsViewModel(
                dialogService: r.resolve(DialogService.self)!,
                notificationsService: r.resolve(NotificationsService.self)!,
                accountService: r.resolve(AccountService.self)!
            )
        }.inObjectScope(.transient)
    }
}
