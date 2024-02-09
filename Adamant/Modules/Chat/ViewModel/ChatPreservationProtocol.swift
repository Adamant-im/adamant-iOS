//
//  ChatPreservationProtocol.swift
//  Adamant
//
//  Created by Andrey Golubenko on 16.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

protocol ChatPreservationProtocol: AnyObject {
    func preserveMessage(_ message: String, forAddress address: String)
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String?
    func setReplayMessage(_ message: MessageModel?, forAddress address: String)
    func getReplayMessage(address: String, thenRemoveIt: Bool) -> MessageModel?
}
