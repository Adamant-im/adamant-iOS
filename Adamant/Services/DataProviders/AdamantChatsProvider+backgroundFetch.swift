//
//  AdamantChatsProvider+backgroundFetch.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantChatsProvider: BackgroundFetchService {
	func fetchBackgroundData(notificationService: NotificationsService, completion: @escaping (FetchResult) -> Void) {
		guard let securedStore = self.securedStore,
			let address = securedStore.get(StoreKey.chatProvider.address) else {
			completion(.failed)
			return
		}
		
		var lastHeight: Int64?
		if let raw = securedStore.get(StoreKey.chatProvider.receivedLastHeight) {
			lastHeight = Int64(raw)
		} else {
			lastHeight = nil
		}
		
		var notifiedCount = 0
		if let raw = securedStore.get(StoreKey.chatProvider.notifiedLastHeight), let notifiedHeight = Int64(raw), let h = lastHeight {
			if h < notifiedHeight {
				lastHeight = notifiedHeight
				
				if let raw = securedStore.get(StoreKey.chatProvider.notifiedMessagesCount), let count = Int(raw) {
					notifiedCount = count
				}
			}
		}
		
		apiService.getMessageTransactions(address: address, height: lastHeight, offset: nil) { result in
			switch result {
			case .success(let transactions):
				if transactions.count > 0 {
					let total = transactions.count
					securedStore.set(String(total + notifiedCount), for: StoreKey.chatProvider.notifiedMessagesCount)
					
					if let newLastHeight = transactions.map({$0.height}).sorted().last {
						securedStore.set(String(newLastHeight), for: StoreKey.chatProvider.notifiedLastHeight)
					}
					
					notificationService.showNotification(title: String.adamantLocalized.notifications.newMessageTitle, body: String.localizedStringWithFormat(String.adamantLocalized.notifications.newMessageBody, total + notifiedCount), type: .newMessages(count: total))
					
					completion(.newData)
				} else {
					completion(.noData)
				}
			
			case .failure(_):
				completion(.failed)
			}
		}
	}
	
	func dropStateData() {
		securedStore.remove(StoreKey.chatProvider.notifiedLastHeight)
		securedStore.remove(StoreKey.chatProvider.notifiedMessagesCount)
	}
}
