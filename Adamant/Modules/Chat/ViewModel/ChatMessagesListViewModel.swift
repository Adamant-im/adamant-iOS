//
//  ChatMessagesListViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

final class ChatMessagesListViewModel {
    
    // MARK: Dependencies
    let avatarService: AvatarService
    
    init(
        avatarService: AvatarService
    ){
        self.avatarService = avatarService
    }
}
