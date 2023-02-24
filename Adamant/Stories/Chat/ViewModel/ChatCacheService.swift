//
//  ChatCacheService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

@MainActor
final class ChatCacheService {
    private var messages: [String: [ChatMessage]] = [:]
    
    func setMessages(address: String, messages: [ChatMessage]) {
        self.messages[address] = messages
    }
    
    func getMessages(address: String) -> [ChatMessage] {
        messages[address] ?? []
    }
}
