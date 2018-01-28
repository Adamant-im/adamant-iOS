//
//  ChatTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ChatTransaction)
public class ChatTransaction: NSManagedObject {
	static let entityName = "ChatTransaction"
	
	var isOutgoing: Bool = false
}
