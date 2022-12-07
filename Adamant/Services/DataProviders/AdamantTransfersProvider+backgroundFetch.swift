//
//  AdamantTransfersProvider+backgroundFetch.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantTransfersProvider: BackgroundFetchService {
    func fetchBackgroundData(notificationsService: NotificationsService, completion: @escaping (FetchResult) -> Void) {
        guard let securedStore = self.securedStore,
            let address: String = securedStore.get(StoreKey.transfersProvider.address) else {
            completion(.failed)
            return
        }
        
        var lastHeight: Int64?
        if let raw: String = securedStore.get(StoreKey.transfersProvider.receivedLastHeight) {
            lastHeight = Int64(raw)
        } else {
            lastHeight = nil
        }
        
        var notifiedCount = 0
        if let raw: String = securedStore.get(StoreKey.transfersProvider.notifiedLastHeight), let notifiedHeight = Int64(raw), let h = lastHeight {
            if h < notifiedHeight {
                lastHeight = notifiedHeight
                
                if let raw: String = securedStore.get(StoreKey.transfersProvider.notifiedTransfersCount), let count = Int(raw) {
                    notifiedCount = count
                }
            }
        }
        
        apiService.getTransactions(forAccount: address, type: .send, fromHeight: lastHeight, offset: 0, limit: 100) { result in
            switch result {
            case .success(let transactions):
                let total = transactions.filter({$0.recipientId == address}).count
                
                if total > 0 {
                    securedStore.set(String(total + notifiedCount), for: StoreKey.transfersProvider.notifiedTransfersCount)
                    
                    if var newLastHeight = transactions.map({$0.height}).sorted().last {
                        newLastHeight += 1 // Server will return new transactions including this one
                        securedStore.set(String(newLastHeight), for: StoreKey.transfersProvider.notifiedLastHeight)
                    }
                    
                    notificationsService.showNotification(title: String.adamantLocalized.notifications.newTransferTitle, body: String.localizedStringWithFormat(String.adamantLocalized.notifications.newTransferBody, total + notifiedCount), type: .newTransactions(count: total))
                    
                    completion(.newData)
                } else {
                    completion(.noData)
                }
                
            case .failure:
                completion(.failed)
            }
        }
    }
    
    func dropStateData() {
        securedStore.remove(StoreKey.transfersProvider.notifiedLastHeight)
        securedStore.remove(StoreKey.transfersProvider.notifiedTransfersCount)
    }
}
