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
		guard let address = securedStore.get(StoreKey.chatProvider.address) else {
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
		
		apiService.getChatTransactions(address: address, height: lastHeight, offset: nil) { [weak self] result in
			switch result {
			case .success(let transactions):
				if transactions.count > 0 {
					let total = transactions.count + notifiedCount
					self?.securedStore.set(String(total), for: StoreKey.chatProvider.notifiedMessagesCount)
					
					if let newLastHeight = transactions.map({$0.height}).sorted().last {
						self?.securedStore.set(String(newLastHeight), for: StoreKey.chatProvider.notifiedLastHeight)
					}
					
					notificationService.showNotification(title: String.adamantLocalized.notifications.newMessageTitle, body: String.localizedStringWithFormat(String.adamantLocalized.notifications.newMessageBody, total), type: .newMessages(count: total))
					
					completion(.newData)
				} else {
					completion(.noData)
				}
			
			case .failure(_):
				completion(.failed)
			}
		}
	}
}
