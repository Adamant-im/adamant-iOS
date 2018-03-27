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
}
