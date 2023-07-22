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
    private let emojiService: EmojiService?
    
    weak var delegate: ChatMenuManagerDelegate?
    var selectedEmoji: String?
    
    // MARK: Init
    
    init(menu: UIMenu, emojiService: EmojiService?) {
        self.menu = menu
        self.emojiService = emojiService
        
        super.init()
    }
    
    func configureContextMenu() -> UIMenu {
        menu
    }
    
    func configureUpperContentViewSize() -> CGSize {
        .init(width: 310, height: 50)
    }
    
    func getUpperContentView() -> AnyView? {
        AnyView(
            ChatReactionsView(
                delegate: self,
                emojis: emojiService?.getFrequentlySelectedEmojis(),
                selectedEmoji: selectedEmoji
            )
        )
    }
}

extension ChatMenuManager: ChatReactionsViewDelegate, ElegantEmojiPickerDelegate {
    func didSelectEmoji(_ emoji: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        delegate?.didReact(emoji == selectedEmoji ? "" : emoji)
    }
    
    func didTapMore() {
        DispatchQueue.onMainAsync {
            let config = ElegantConfiguration(
                showRandom: false,
                showReset: false,
                defaultSkinTone: .Light
            )
            let picker = ElegantEmojiPicker(delegate: self, configuration: config)
            picker.definesPresentationContext = true
            self.rootViewController()?.present(picker, animated: true)
        }
    }
    
    func emojiPicker (
        _ picker: ElegantEmojiPicker,
        didSelectEmoji emoji: Emoji?
    ) {
        guard let emoji = emoji?.emoji else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        delegate?.didReact(emoji)
    }
}

private extension ChatMenuManager {
    func rootViewController() -> UIViewController? {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        guard let windowScene = scene as? UIWindowScene else {
            return nil
        }
        
        var topController = windowScene.keyWindow?.rootViewController
        
        while (topController?.presentedViewController != nil) {
            topController = topController?.presentedViewController
        }
        return topController
    }
}
