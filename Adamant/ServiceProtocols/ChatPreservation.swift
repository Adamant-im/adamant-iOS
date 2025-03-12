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
    
    func preserveMessage(_ message: String, forAddress address: String) {
        preservedMessages[address] = message
        updateNotifier.send()
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
    
    func setReplyMessage(_ message: MessageModel?, forAddress address: String) {
        preservedReplayMessage[address] = message
        updateNotifier.send()
    }
    
    func getReplyMessage(address: String, thenRemoveIt: Bool) -> MessageModel? {
        guard let replayMessage = preservedReplayMessage[address] else {
            return nil
        }
        
        if thenRemoveIt {
            preservedMessages.removeValue(forKey: address)
            updateNotifier.send()
        }
        
        return replayMessage
    }
    
    func preserveFiles(_ files: [FileResult]?, forAddress address: String) {
        preservedFiles[address] = files
        updateNotifier.send()
    }
    
    func getPreservedFiles(
        for address: String,
        thenRemoveIt: Bool
    ) -> [FileResult]? {
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
