//
//  ChatItemsListMapper.swift
//  Adamant
//
//  Created by Andrew G on 09.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import ChatKit

struct ChatItemsListMapper {
    let chatItemMapper: ChatItemMapper
    
    func map(transactions: [ChatTransaction]) -> [ChatItemModel] {
        [.loader, .date("Some date")] + transactions.map { chatItemMapper.map(transaction: $0) }
    }
}
