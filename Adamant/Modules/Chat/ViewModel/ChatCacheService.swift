//
//  ChatCacheService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

@MainActor
final class ChatCacheService {
    private var messages: [String: [ChatMessage]] = [:]
    private var subscriptions = Set<AnyCancellable>()
    
    nonisolated init() {
        Task { await setup() }
    }
    
    func setMessages(address: String, messages: [ChatMessage]) {
        self.messages[address] = messages
    }
    
    func getMessages(address: String) -> [ChatMessage]? {
        messages[address]
    }
}

private extension ChatCacheService {
    func setup() {
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { @MainActor [weak self] _ in self?.messages = .init() }
            .store(in: &subscriptions)
    }
}
