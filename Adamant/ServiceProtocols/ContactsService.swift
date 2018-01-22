//
//  ContactsService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

protocol ContactsService {
	// MARK: - Known contacts
	func isKnownContact(address: String) -> Bool
	func nameFor(address: String) -> String?
	func translated(message: String, from address: String) -> String?
}
