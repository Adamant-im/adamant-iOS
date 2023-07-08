//
//  ChatMenuManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.05.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SwiftUI
import ElegantEmojiPicker
import AdvancedContextMenuKit

protocol ChatMenuManagerDelegate: AnyObject {
    func didReact(_ emoji: String)
}

final class ChatMenuManager: NSObject, AdvancedContextMenuManagerDelegate {
    private let menu: UIMenu
    
    weak var delegate: ChatMenuManagerDelegate?
    var menuAlignment: Alignment
    
    // MARK: Init
    
    init(menu: UIMenu, menuAlignment: Alignment) {
        self.menu = menu
        self.menuAlignment = menuAlignment
        
        super.init()
    }
    
    func configureContextMenu() -> UIMenu {
        menu
    }
    
    func configureContextMenuAlignment() -> Alignment {
        menuAlignment
    }
    
    func configureUpperContentViewSize() -> CGSize {
        .init(width: 290, height: 50)
    }
    
    func getUpperContentView() -> AnyView? {
        return AnyView(ChatReactionsView(delegate: self))
    }
}

extension ChatMenuManager: ChatReactionsViewDelegate, ElegantEmojiPickerDelegate {
    func didSelectEmoji(_ emoji: String) {
        print("didSelectEmoji=\(emoji)")
        delegate?.didReact(emoji)
    //    contextMenu.dismiss()
    }
    
    func didTapMore() {
        DispatchQueue.main.async {
            let config = ElegantConfiguration(
                showRandom: false,
                showReset: false,
                defaultSkinTone: .Light
            )
            let picker = ElegantEmojiPicker(delegate: self, configuration: config)
            picker.definesPresentationContext = true
            self.topMostController().present(picker, animated: true)
        }
    }
    
    func topMostController() -> UIViewController {
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    func emojiPicker (
        _ picker: ElegantEmojiPicker,
        didSelectEmoji emoji: Emoji?
    ) {
        guard let emoji = emoji?.emoji else { return }
        print("emojiPicker=\(emoji)")
        delegate?.didReact(emoji)
      //  contextMenu.dismiss()
    }
}

final class ChatMenuManagerOld: NSObject, UIContextMenuInteractionDelegate {
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
