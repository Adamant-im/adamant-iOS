//
//  ChatPreservation.swift
//  Adamant
//
//  Created by Yana Silosieva on 08.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import Combine

final class ChatPreservation: ChatPreservationProtocol {
    @Atomic private var preservedMessages: [String: String] = [:]
    @Atomic private var replayMessage: [String: MessageModel] = [:]
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    
    init() {
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.clearPreservedMessages()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func clearPreservedMessages() {
        preservedMessages = [:]
        replayMessage = [:]
    }
    
    func preserveMessage(_ message: String, forAddress address: String) {
        preservedMessages[address] = message
    }
    
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String? {
        guard let message = preservedMessages[address] else {
            return nil
        }

        if thenRemoveIt {
            preservedMessages.removeValue(forKey: address)
        }

        return message
    }
    
    func setReplyMessage(_ message: MessageModel?, forAddress address: String) {
        replayMessage[address] = message
    }
    
    func getReplyMessage(address: String, thenRemoveIt: Bool) -> MessageModel? {
        guard let replayMessage = replayMessage[address] else {
            return nil
        }
        
        if thenRemoveIt {
            preservedMessages.removeValue(forKey: address)
        }
        
        return replayMessage
    }
}
