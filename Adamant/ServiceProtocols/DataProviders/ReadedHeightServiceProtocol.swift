//
//  ReadedHeightProvider.swift
//  Adamant
//
//  Created by Аркадий Торвальдс on 30.09.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

protocol ReadedHeightServiceProtocol {
    func markMessageAsRead() async
    func markChatAsRead() async
    func getLastReadedHeight(adress: String) async -> Int
}
