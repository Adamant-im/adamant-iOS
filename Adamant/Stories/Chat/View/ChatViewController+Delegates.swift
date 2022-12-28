//
//  ChatViewController+Delegates.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import MessageKit
import InputBarAccessoryView

extension ChatViewController {
    struct Delegates {
        let dataSource: MessagesDataSource
        let inputBarDelegate: InputBarAccessoryViewDelegate
        let layoutDelegate: MessagesLayoutDelegate
        let displayDelegate: MessagesDisplayDelegate
    }
}
