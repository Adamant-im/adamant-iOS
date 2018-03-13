//
//  AdamantTransfersProvider+backgroundFetch.swift
//  Adamant
//
//  Created by Anokhov Pavel on 13.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantTransfersProvider: BackgroundFetchService {
	func fetchBackgroundData(notificationService: NotificationsService, completion: @escaping (FetchResult) -> Void) {
		guard let address = securedStore.get(StoreKey.transfersProvider.address) else {
			completion(.failed)
			return
		}
		
		var lastHeight: Int64?
		if let raw = securedStore.get(StoreKey.transfersProvider.receivedLastHeight) {
			lastHeight = Int64(raw)
		} else {
			lastHeight = nil
		}
		
		var notifiedCount = 0
		if let raw = securedStore.get(StoreKey.transfersProvider.notifiedLastHeight), let notifiedHeight = Int64(raw), let h = lastHeight {
			if h < notifiedHeight {
				lastHeight = notifiedHeight
				
				if let raw = securedStore.get(StoreKey.transfersProvider.notifiedTransfersCount), let count = Int(raw) {
					notifiedCount = count
				}
			}
		}
		
		apiService.getTransactions(forAccount: address, type: .send, fromHeight: lastHeight) { [weak self] result in
			switch result {
			case .success(let transactions):
				let income = transactions.filter({$0.recipientId == address}).count
				
				if income > 0 {
					let total = income + notifiedCount
					self?.securedStore.set(String(total), for: StoreKey.transfersProvider.notifiedTransfersCount)
					
					if var newLastHeight = transactions.map({$0.height}).sorted().last {
//						newLastHeight += 1 // Server will return new transactions including this one
						self?.securedStore.set(String(newLastHeight), for: StoreKey.transfersProvider.notifiedLastHeight)
					}
					
					notificationService.showNotification(title: String.adamantLocalized.notifications.newTransferTitle, body: String.localizedStringWithFormat(String.adamantLocalized.notifications.newTransferBody, total), type: .newTransactions(count: total))
					
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
