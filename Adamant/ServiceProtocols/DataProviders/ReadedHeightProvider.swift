//
//  ReadedHeightProvider.swift
//  Adamant
//
//  Created by Аркадий Торвальдс on 30.09.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

protocol ReadedHeightProvider {
    func markMessageAsRead()
    func markChatAsRead()
    func getLastReadedHeight(adress: String) -> UInt64
}
