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
    private let assembler: Assembler
    
    init(parent: Assembler) {
        assembler = .init([NotificationSoundAssembly()], parent: parent)
    }
    
    @MainActor
    func makeView(target: NotificationTarget) -> NotificationSoundsView {
        let viewModel = assembler.resolve(NotificationSoundsViewModel.self)!
        viewModel.setup(notificationTarget: target)
        let view = NotificationSoundsView(viewModel: viewModel)
        
        return view
    }
}

private struct NotificationSoundAssembly: Assembly {
    func assemble(container: Container) {
        container.register(NotificationSoundsViewModel.self) { r in
            NotificationSoundsViewModel(
                notificationsService: r.resolve(NotificationsService.self)!,
                target: .baseMessage
            )
        }
    }
}
