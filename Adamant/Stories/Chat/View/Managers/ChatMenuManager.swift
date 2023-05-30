//
//  ChatMenuManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.05.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

final class ChatMenuManager: NSObject, UIContextMenuInteractionDelegate {
    private let menu: UIMenu
    
    var backgroundColor: UIColor?
    
    // MARK: Init
    
    init(menu: UIMenu, backgroundColor: UIColor?) {
        self.menu = menu
        self.backgroundColor = backgroundColor
        
        super.init()
    }
    
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            guard let self = self else { return nil }
            return self.menu
        })
    }
    
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        highlightPreviewForItemWithIdentifier identifier: NSCopying
    ) -> UITargetedPreview? {
        guard let backgroundColor = backgroundColor else { return nil }
        
        return makeTargetedPreview(
            for: configuration,
            interaction: interaction,
            backgroundColor: backgroundColor
        )
    }
    
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configuration: UIContextMenuConfiguration,
        dismissalPreviewForItemWithIdentifier identifier: NSCopying
    ) -> UITargetedPreview? {
        guard backgroundColor != nil else {
            return makeTargetedPreview(
                for: configuration,
                interaction: interaction,
                backgroundColor: .clear
            )
        }
        
        return nil
    }
    
    private func makeTargetedPreview(
        for configuration: UIContextMenuConfiguration,
        interaction: UIContextMenuInteraction,
        backgroundColor: UIColor
    ) -> UITargetedPreview? {
        guard let view = interaction.view else { return nil }
        
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = backgroundColor
        return UITargetedPreview(view: view, parameters: parameters)
    }
}
