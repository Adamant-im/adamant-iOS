//
//  KnownContactsService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct KnownMessage: Codable {
	let key: String
	let translationKey: String
	
	// TODO: remove this
	let message: String
}

struct KnownContact: Codable {
	let address: String
	let title: String
	let messageKeys: [KnownMessage]?
}

public class KnownContactsService {
	let knownContacts: [String:KnownContact]
	
	init(contactsJsonUrl url: URL) throws {
		let raw = try Data(contentsOf: url)
		let knownContacts = try JSONDecoder().decode([KnownContact].self, from: raw)
		
		self.knownContacts = knownContacts.reduce(into: [String:KnownContact](), { (result, contact) in
			result[contact.address] = contact
		})
	}
}


// MARK: - ContactsService
extension KnownContactsService: ContactsService {
	func isKnownContact(address: String) -> Bool {
		return knownContacts[address] != nil
	}
	
	func nameFor(address: String) -> String? {
		return knownContacts[address]?.title
	}
	
	func translated(message: String, from address: String) -> String? {
		guard let contact = knownContacts[address] else {
			return nil
		}
		
		return contact.messageKeys?.first(where: {message.range(of: $0.key) != nil})?.message
	}
}
