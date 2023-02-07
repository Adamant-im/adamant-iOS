//
//  ChatInputBarManager.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import InputBarAccessoryView
import Foundation

final class ChatInputBarManager: InputBarAccessoryViewDelegate {
    private let sendMessageAction: (String) -> Void
    
    init(sendMessageAction: @escaping (String) -> Void) {
        self.sendMessageAction = sendMessageAction
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        sendMessageAction(text)
    }
}
