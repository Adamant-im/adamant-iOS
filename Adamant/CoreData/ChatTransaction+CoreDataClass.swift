//
//  ChatTransaction+CoreDataClass.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ChatTransaction)
public class ChatTransaction: BaseTransaction {
	var statusEnum: MessageStatus {
		get { return MessageStatus(rawValue: self.status) ?? .failed }
		set { self.status = newValue.rawValue }
	}
}
