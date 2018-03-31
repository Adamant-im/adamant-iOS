//
//  Chatroom+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Chatroom)
public class Chatroom: NSManagedObject {
	static let entityName = "Chatroom"
	
	func markAsReaded() {
		if hasUnreadMessages {
			hasUnreadMessages = false
		}
		
		if let trs = transactions as? Set<ChatTransaction> {
			trs.filter { $0.isUnread }.forEach { $0.isUnread = false }
		}
	}
	
	private var semaphore: DispatchSemaphore?
	
	func updateLastTransaction() {
		var semaphore = self.semaphore
		
		if let semaphore = semaphore {
			semaphore.wait()
		} else {
			semaphore = DispatchSemaphore(value: 1)
		}
		
		self.semaphore = semaphore
		defer {
			self.semaphore = nil
			semaphore?.signal()
		}
		
		if let transactions = transactions as? Set<ChatTransaction> {
			if let newest = transactions.sorted(by: { (lhs: ChatTransaction, rhs: ChatTransaction) in
				guard let l = lhs.date as Date? else {
					return true
				}
				
				guard let r = rhs.date as Date? else {
					return false
				}
				
				switch l.compare(r) {
				case .orderedAscending:
					return true
					
				case .orderedDescending:
					return false
					
				case .orderedSame:
					return lhs.height < rhs.height
				}
			}).last {
				if newest != lastTransaction {
					lastTransaction = newest
					updatedAt = newest.date
				}
			} else if lastTransaction != nil {
				lastTransaction = nil
				updatedAt = nil
			}
		}
	}
}
