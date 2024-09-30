//
//  ReadedHeightService.swift
//  Adamant
//
//  Created by Аркадий Торвальдс on 30.09.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class ReadedHeightService {
    
    private var chatsReadHeight: [String: Int] {
        get {
            let rv = UserDefaults.standard.dictionary(forKey: StoreKey.chatProvider.readedHeights) as? [String: Int]
            return rv ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: StoreKey.chatProvider.readedHeights)
        }
    }
    
}

extension ReadedHeightService: ReadedHeightProvider {
    func markMessageAsRead() {}
    
    func markChatAsRead() {}
    
    func getLastReadedHeight(adress: String) -> UInt64 {
        return UInt64(chatsReadHeight[adress] ?? .max)
    }
}
