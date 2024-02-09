//
//  ChatPreservation.swift
//  Adamant
//
//  Created by Yana Silosieva on 08.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

final class ChatPreservation: ChatPreservationProtocol {
    private var preservedMessagess: [String: String] = [:]
    private var replayMessage: [String: MessageModel] = [:]
    
    func preserveMessage(_ message: String, forAddress address: String) {
        preservedMessagess[address] = message
    }
    
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String? {
        guard let message = preservedMessagess[address] else {
            return nil
        }

        if thenRemoveIt {
            preservedMessagess.removeValue(forKey: address)
        }

        return message
    }
    
    func setReplayMessage(_ message: MessageModel?, forAddress address: String) {
        replayMessage[address] = message
    }
    
    func getReplayMessage(address: String, thenRemoveIt: Bool) -> MessageModel? {
        guard let replayMessage = replayMessage[address] else {
            return nil
        }
        
        if thenRemoveIt {
            preservedMessagess.removeValue(forKey: address)
        }
        
        return replayMessage
    }
}
