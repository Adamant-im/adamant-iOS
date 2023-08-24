//
//  OverlayHostingController.swift
//  
//
//  Created by Andrey Golubenko on 24.08.2023.
//

import SwiftUI
import CommonKit

@MainActor
final class OverlayHostingController<Content: View>: UIHostingController<Content> {
    private let dismissAction: @MainActor () -> Void
    
    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(
                input: UIKeyCommand.inputEscape,
                modifierFlags: [],
                action: #selector(dismissOverlay)
            )
        ]
        commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        return commands
    }
    
    init(rootView: Content, dismissAction: @escaping @MainActor () -> Void) {
        self.dismissAction = dismissAction
        super.init(rootView: rootView)
    }
    
    required dynamic init?(coder aDecoder: NSCoder) {
        self.dismissAction = {}
        super.init(coder: aDecoder)
        assertionFailure("init(coder:) has not been implemented")
    }
    
    @objc private func dismissOverlay() {
        dismissAction()
    }
}
