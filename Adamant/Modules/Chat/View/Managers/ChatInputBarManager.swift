//
//  ChatInputBarManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import InputBarAccessoryView
import Foundation

@MainActor
final class ChatInputBarManager: InputBarAccessoryViewDelegate {
    private let viewModel: ChatViewModel
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    nonisolated func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        MainActor.assumeIsolatedSafe {
            guard viewModel.canSendMessage(withText: text) else { return }
            inputBar.inputTextView.text = ""
            viewModel.sendMessage(text: text)
        }
    }
}
