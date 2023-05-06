//
//  AdamantChatsProvider+backgroundFetch.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantChatsProvider: BackgroundFetchService {
    func fetchBackgroundData(notificationsService: NotificationsService) async -> FetchResult {
        guard let address: String = securedStore.get(StoreKey.chatProvider.address) else {
            return .failed
        }
        
        var lastHeight: Int64?
        if let raw: String = securedStore.get(StoreKey.chatProvider.receivedLastHeight) {
            lastHeight = Int64(raw)
        } else {
            lastHeight = nil
        }
        
        var notifiedCount = 0
        if let raw: String = securedStore.get(StoreKey.chatProvider.notifiedLastHeight), let notifiedHeight = Int64(raw), let h = lastHeight {
            if h < notifiedHeight {
                lastHeight = notifiedHeight
                
                if let raw: String = securedStore.get(StoreKey.chatProvider.notifiedMessagesCount), let count = Int(raw) {
                    notifiedCount = count
                }
            }
        }
        
        do {
            let transactions = try await apiService.getMessageTransactions(
                address: address,
                height: lastHeight,
                offset: nil
            )
            
            guard transactions.count > 0 else { return .noData }
            
            let total = transactions.count
            securedStore.set(
                String(total + notifiedCount),
                for: StoreKey.chatProvider.notifiedMessagesCount
            )
            
            if let newLastHeight = transactions.map({$0.height}).sorted().last {
                securedStore.set(
                    String(newLastHeight),
                    for: StoreKey.chatProvider.notifiedLastHeight
                )
            }
            
            notificationsService.showNotification(
                title: String.adamantLocalized.notifications.newMessageTitle,
                body: String.localizedStringWithFormat(
                    String.adamantLocalized.notifications.newMessageBody,
                    total + notifiedCount
                ),
                type: .newMessages(count: total)
            )
            
            return .newData
        } catch {
            return .failed
        }
    }
}
