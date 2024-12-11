//
//  ChatAction.swift
//  Adamant
//
//  Created by Andrey Golubenko on 27.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import CommonKit

enum ChatAction {
    case forceUpdateTransactionStatus(id: String)
    case openTransactionDetails(id: String)
    case reply(message: MessageModel)
    case scrollTo(message: ChatMessageReplyCell.Model)
    case swipeState(state: SwipeableView.State)
    case copy(text: String)
    case copyInPart(text:String)
    case report(id: String)
    case remove(id: String)
    case react(id: String, emoji: String)
    case presentMenu(arg: ChatContextMenuArguments)
    case openFile(messageId: String, file: ChatFile)
    case autoDownloadContentIfNeeded(messageId: String, files: [ChatFile])
    case forceDownloadAllFiles(messageId: String, files: [ChatFile])
}
