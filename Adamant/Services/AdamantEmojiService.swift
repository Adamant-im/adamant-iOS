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

final class AdamantEmojiService: EmojiService {
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    private var notificationsSet: Set<AnyCancellable> = []
    private var defaultEmojis = ["😂", "🤔", "😁", "👍", "👌"]
    private let maxEmojiCount = 4
    
    // MARK: Lifecycle
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedOut() {
        securedStore.remove(StoreKey.emojis.emojis)
    }
    
    // MARK: Update data
    
    func getFrequentlySelectedEmojis() -> [String] {
        guard let storedEmojis: [String: Int] = securedStore.get(
            StoreKey.emojis.emojis
        ) else {
            return defaultEmojis
        }
        
        let sortedEmojis = storedEmojis.sorted { $0.value > $1.value }
        
        if sortedEmojis.count >= maxEmojiCount {
            return Array(sortedEmojis.prefix(maxEmojiCount)).map { $0.key }
        }
        
        let missingEmojisCount = maxEmojiCount - sortedEmojis.count
        let missingEmojis = defaultEmojis.dropLast(missingEmojisCount)
        let combinedEmojis = missingEmojis + sortedEmojis.map { $0.key }
        
        return Array(combinedEmojis.prefix(maxEmojiCount))
    }

    func updateFrequentlySelectedEmojis(selectedEmoji: String) {
        var storedEmojis: [String: Int] = securedStore.get(
            StoreKey.emojis.emojis
        ) ?? [:]
        
        if let count = storedEmojis[selectedEmoji] {
            storedEmojis[selectedEmoji] = count + 1
        } else {
            storedEmojis[selectedEmoji] = 1
        }
        
        securedStore.set(storedEmojis, for: StoreKey.emojis.emojis)
    }
}
