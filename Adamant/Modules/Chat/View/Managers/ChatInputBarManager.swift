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
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard viewModel.canSendMessage(withText: text) else { return }
        inputBar.inputTextView.text = ""
        viewModel.sendMessage(text: text)
    }
}
