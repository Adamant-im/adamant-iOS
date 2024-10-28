//
//  AdamantEmojiService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine
import CommonKit

final class AdamantEmojiService: EmojiService, @unchecked Sendable {
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    @Atomic private var defaultEmojis = ["😂": 3, "🔥": 3, "😁": 3, "👍": 2, "👌": 2, "❤️️️️️️️": 2, "🙂": 2, "🤔": 2, "👋": 2, "🙏": 2, "😳": 2, "🎉": 2]
    private let maxEmojiCount = 12
    private let incCount = 4
    private let decCount = 2
    
    // MARK: Lifecycle
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                self?.userLoggedIn()
            }
            .store(in: &notificationsSet)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedOut() {
        securedStore.remove(StoreKey.emojis.emojis)
    }
    
    private func userLoggedIn() {
        setDefaultEmojiIfNeeded()
    }
    
    // MARK: Update data
    
    private func setDefaultEmojiIfNeeded() {
        let emojis: [String: Int]? = securedStore.get(
            StoreKey.emojis.emojis
        )
        
        guard emojis == nil else { return }
        
        securedStore.set(defaultEmojis, for: StoreKey.emojis.emojis)
    }
    
    func getFrequentlySelectedEmojis() -> [String] {
        let storedEmojis: [String: Int] = securedStore.get(
            StoreKey.emojis.emojis
        ) ?? defaultEmojis
        
        let sortedEmojis = storedEmojis.sorted { (emoji1, emoji2) in
            if emoji1.value == emoji2.value {
                return emoji1.key > emoji2.key
            } else {
                return emoji1.value > emoji2.value
            }
        }
        
        return Array(sortedEmojis.prefix(maxEmojiCount)).map { $0.key }
    }

    func updateFrequentlySelectedEmojis(
        selectedEmoji: String,
        type: EmojiUpdateType
    ) {
        var storedEmojis: [String: Int] = securedStore.get(
            StoreKey.emojis.emojis
        ) ?? defaultEmojis
        
        let value = type == .increment
        ? incCount
        : -decCount
        
        if let count = storedEmojis[selectedEmoji] {
            storedEmojis[selectedEmoji] = count + value
        } else {
            storedEmojis[selectedEmoji] = value
        }
        
        securedStore.set(storedEmojis, for: StoreKey.emojis.emojis)
    }
}
