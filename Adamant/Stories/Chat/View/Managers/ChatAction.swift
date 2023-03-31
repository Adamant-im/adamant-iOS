//
//  ChatAction.swift
//  Adamant
//
//  Created by Andrey Golubenko on 27.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

enum ChatAction {
    case forceUpdateTransactionStatus(id: String)
    case openTransactionDetails(id: String)
    case reply(message: MessageModel)
}
