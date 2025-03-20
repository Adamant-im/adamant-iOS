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

final class ChatPreservation: ChatPreservationProtocol, @unchecked Sendable {
    @Atomic private var preservedMessages: [String: String] = [:]
    @Atomic private var preservedReplayMessage: [String: MessageModel] = [:]
    @Atomic private var preservedFiles: [String: [FileResult]] = [:]
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    
    var updateNotifier = ObservableSender<Void>()
    init() {
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.clearPreservedMessages()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func clearPreservedMessages() {
        preservedMessages = [:]
        preservedReplayMessage = [:]
        preservedFiles = [:]
        
        updateNotifier.send()
    }
    func preserveChatState(
        message: String?,
        replyMessage: MessageModel?,
        files: [FileResult]?,
        forAddress address: String
    ) {
        var shouldNotify = false

        if let message = message, !message.isEmpty {
            preservedMessages[address] = message
            shouldNotify = true
        }

        if let replyMessage = replyMessage {
            preservedReplayMessage[address] = replyMessage
            shouldNotify = true
        }

        if let files = files {
            preservedFiles[address] = files
            shouldNotify = true
        }

        if shouldNotify {
            updateNotifier.send()
        }
    }
    
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String? {
        guard let message = preservedMessages[address] else {
            return nil
        }
        
        if thenRemoveIt {
            preservedMessages.removeValue(forKey: address)
            updateNotifier.send()
        }
        
        return message
    }
    
    func getReplyMessage(address: String, thenRemoveIt: Bool) -> MessageModel? {
        guard let replyMessage = preservedReplayMessage[address] else {
            return nil
        }
        
        if thenRemoveIt {
            preservedReplayMessage.removeValue(forKey: address)
            updateNotifier.send()
        }
        
        return replyMessage
    }
    
    func getPreservedFiles(for address: String, thenRemoveIt: Bool) -> [FileResult]? {
        guard let files = preservedFiles[address] else {
            return nil
        }
        
        if thenRemoveIt {
            preservedFiles.removeValue(forKey: address)
            updateNotifier.send()
        }
        
        return files
    }
}
