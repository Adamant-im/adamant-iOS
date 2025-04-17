//
//  ChatPreservation.swift
//  Adamant
//
//  Created by Yana Silosieva on 08.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation

final class ChatPreservation: ChatPreservationProtocol, @unchecked Sendable {
    @Atomic private var preservedMessages: [String: String] = [:]
    @Atomic private var preservedReplayMessage: [String: MessageModel] = [:]
    @Atomic private var preservedFiles: [String: [FileResult]] = [:]
    @Atomic private var notificationsSet: Set<AnyCancellable> = []

    var updateNotifier = ObservableSender<Void>()
    var forseUpdateNotifier = ObservableSender<Void>()
    
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
        forAddress address: String,
        isForsedUpdate: Bool = false
    ) {
        var shouldNotify = false

        if let message = message, !message.isEmpty {
            preservedMessages[address] = message
            shouldNotify = true
        } else if preservedMessages[address] != nil {
            preservedMessages.removeValue(forKey: address)
            shouldNotify = true
        }

        if let replyMessage = replyMessage {
            preservedReplayMessage[address] = replyMessage
            shouldNotify = true
        } else if preservedReplayMessage[address] != nil {
            preservedReplayMessage.removeValue(forKey: address)
            shouldNotify = true
        }

        if let files = files {
            preservedFiles[address] = files
            shouldNotify = true

        } else if preservedFiles[address] != nil {
            preservedFiles.removeValue(forKey: address)
            shouldNotify = true
        }

        if shouldNotify {
            updateNotifier.send()
        }
        
        if isForsedUpdate {
            forseUpdateNotifier.send()
        }
    }

    func getPreservedMessageFor(address: String) -> String? {
        guard let message = preservedMessages[address] else {
            return nil
        }

        return message
    }

    func getReplyMessage(address: String) -> MessageModel? {
        guard let replyMessage = preservedReplayMessage[address] else {
            return nil
        }

        return replyMessage
    }

    func getPreservedFiles(for address: String) -> [FileResult]? {
        guard let files = preservedFiles[address] else {
            return nil
        }

        return files
    }
}
