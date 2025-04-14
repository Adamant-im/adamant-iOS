//
//  ChatInputBarManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import InputBarAccessoryView

@MainActor
final class ChatInputBarManager: InputBarAccessoryViewDelegate {
    private let viewModel: ChatViewModel

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }

    nonisolated func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        Task { @MainActor in
            guard await viewModel.canSendMessage(withText: text) else { return }
            viewModel.sendMessage(text: text)
        }
    }
}
