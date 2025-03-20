//
//  ChatPreservationProtocol.swift
//  Adamant
//
//  Created by Andrey Golubenko on 16.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

protocol ChatPreservationProtocol: AnyObject, Sendable {
    var updateNotifier: ObservableSender<Void> { get }
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String?
    func getReplyMessage(address: String, thenRemoveIt: Bool) -> MessageModel?
    func preserveChatState(message: String?, replyMessage: MessageModel?, files: [FileResult]?, forAddress address: String)
    func getPreservedFiles(
        for address: String,
        thenRemoveIt: Bool
    ) -> [FileResult]?
}
