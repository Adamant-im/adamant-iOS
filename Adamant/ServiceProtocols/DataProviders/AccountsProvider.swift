//
//  AccountsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

enum AccountsProviderResult {
	case success(CoreDataAccount)
	case notFound
	case invalidAddress
	case serverError(Error)
}

protocol AccountsProvider {
	
	/// Search for fetched account, if not found, asks server for account.
	///
	/// - Returns: Account, if found, created in main viewContext
	func getAccount(byAddress address: String, completion: @escaping (AccountsProviderResult) -> Void)
	
	/* That one bugged. Will be fixed later. Maybe. */
	/// Search for fetched account, if not found, asks server for account.
	///
	/// - Returns: Account, if found, created in main viewContext
//	func getAccount(byPublicKey publicKey: String, completion: @escaping (AccountsProviderResult) -> Void)
	
	/// Check locally if has account with specified address
	func hasAccount(address: String, completion: @escaping (Bool) -> Void)
}

// MARK: - Known contacts
enum AdamantContacts {
	static let systemAddresses: [String] = {
		return [AdamantContacts.adamantIco.name, AdamantContacts.adamantBountyWallet.name]
	}()
	
	case adamantBountyWallet
	case adamantIco
	
	var name: String {
		switch self {
		case .adamantBountyWallet: return "ADAMANT Bounty"
		case .adamantIco: return "ADAMANT ICO"
		}
	}
	
	var address: String {
		switch self {
		case .adamantBountyWallet: return "U15423595369615486571"
		case .adamantIco: return "U7047165086065693428"
		}
	}
	
	var avatar: String {
		return "avatar_bots"
	}
	
	var messages: [String:String] {
		switch self {
		case .adamantBountyWallet:
			return ["chats.welcome_message": NSLocalizedString("Chats.WelcomeMessage", comment: "Known contacts: Adamant welcome message")]
			
		case .adamantIco:
			return [
				"chats.preico_message": NSLocalizedString("Chats.PreIcoMessage", comment: "Known contacts: Adamant pre ICO message"),
				"chats.ico_message": NSLocalizedString("Chats.IcoMessage", comment: "Known contacts: Adamant ICO message")
			]
		}
	}
}
