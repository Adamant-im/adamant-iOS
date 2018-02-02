//
//  Chatroom+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Chatroom)
public class Chatroom: NSManagedObject {
	static let entityName = "Chatroom"
	
	/// returns title if not nil, otherwise partner's address
	var identity: String? {
		return self.title ?? self.partner?.address
	}
}
