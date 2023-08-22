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
    func getContentView() -> UIView?
}

extension ChatMenuManagerDelegate {
    func getContentView() -> UIView? { return nil }
}

@MainActor
final class ChatMenuManager: NSObject, AdvancedContextMenuManagerDelegate {
    private let menu: AMenuSection
    var emojiService: EmojiService?
    
    weak var delegate: ChatMenuManagerDelegate?
    var selectedEmoji: String?
    
    // MARK: Init
    
    init(menu: AMenuSection, emojiService: EmojiService?) {
        self.menu = menu
        self.emojiService = emojiService
        
        super.init()
    }
    
    func configureContextMenu() -> AMenuSection {
        menu
    }
    
    func configureUpperContentViewSize() -> CGSize {
        .init(width: 310, height: 50)
    }
    
    func getUpperContentView() -> AnyView? {
        AnyView(
            ChatReactionsView(
                delegate: self,
                emojis: getFrequentlySelectedEmojis(selectedEmoji: selectedEmoji),
                selectedEmoji: selectedEmoji
            )
        )
    }
    
    func getContentView() -> UIView? {
        delegate?.getContentView()
    }
}

extension ChatMenuManager: ChatReactionsViewDelegate, ElegantEmojiPickerDelegate {
    func didSelectEmoji(_ emoji: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let pickedEmoji = emoji == selectedEmoji ? "" : emoji
        
        delegate?.didReact(pickedEmoji)
        
        if !pickedEmoji.isEmpty {
            emojiService?.updateFrequentlySelectedEmojis(
                selectedEmoji: pickedEmoji,
                type: .increment
            )
        }
        
        if let selectedEmoji = selectedEmoji {
            emojiService?.updateFrequentlySelectedEmojis(
                selectedEmoji: selectedEmoji,
                type: .decrement
            )
        }
    }
    
    @MainActor
    func didTapMore() {
        let config = ElegantConfiguration(
            showRandom: false,
            showReset: false,
            defaultSkinTone: .Light
        )
        let picker = ElegantEmojiPicker(delegate: self, configuration: config)
        picker.definesPresentationContext = true
        self.rootViewController()?.present(picker, animated: true)
    }
    
    func emojiPicker (
        _ picker: ElegantEmojiPicker,
        didSelectEmoji emoji: Emoji?
    ) {
        guard let emoji = emoji?.emoji else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        let pickedEmoji = emoji == selectedEmoji ? "" : emoji
        
        delegate?.didReact(pickedEmoji)
        
        if !pickedEmoji.isEmpty {
            emojiService?.updateFrequentlySelectedEmojis(
                selectedEmoji: pickedEmoji,
                type: .increment
            )
        }
        
        if let selectedEmoji = selectedEmoji {
            emojiService?.updateFrequentlySelectedEmojis(
                selectedEmoji: selectedEmoji,
                type: .decrement
            )
        }
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
    
    func getFrequentlySelectedEmojis(selectedEmoji: String?) -> [String]? {
        var emojis = emojiService?.getFrequentlySelectedEmojis()
        guard let selectedEmoji = selectedEmoji else { return emojis }
        
        if let index = emojis?.firstIndex(of: selectedEmoji) {
            emojis?.remove(at: index)
        }
        emojis?.insert(selectedEmoji, at: 0)
        
        return emojis
    }
}
