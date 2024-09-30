//
//  NotificationSoundsFactory.swift
//  Adamant
//
//  Created by Yana Silosieva on 20.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Swinject
import SwiftUI

struct NotificationSoundsFactory {
    private let parent: Assembler
    private let assemblies = [NotificationSoundAssembly()]
    
    init(parent: Assembler) {
        self.parent = parent
    }
    
    @MainActor
    func makeView(target: NotificationTarget) -> NotificationSoundsView {
        let assembler = Assembler(assemblies, parent: parent)
        let viewModel = {
            assembler.resolver.resolve(NotificationSoundsViewModel.self, argument: target)!
        }
        
        let view = NotificationSoundsView(viewModel: viewModel)
        
        return view
    }
}

private struct NotificationSoundAssembly: Assembly {
    func assemble(container: Container) {
        container.register(NotificationSoundsViewModel.self) { (r, target: NotificationTarget) in
            NotificationSoundsViewModel(
                notificationsService: r.resolve(NotificationsService.self)!,
                target: target,
                dialogService: r.resolve(DialogService.self)!
            )
        }.inObjectScope(.transient)
    }
}
