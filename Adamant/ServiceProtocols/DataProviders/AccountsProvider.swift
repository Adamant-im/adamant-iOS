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
	case notFound(address: String)
	case invalidAddress(address: String)
	case serverError(Error)
	case networkError(Error)
	
	var localized: String {
		switch self {
		case .success(_):
			return ""
			
		case .notFound(let address):
			return String.localizedStringWithFormat(String.adamantLocalized.sharedErrors.accountNotFound, address) 
			
		case .invalidAddress(let address):
			return String.localizedStringWithFormat(NSLocalizedString("AccountsProvider.Error.AddressNotValidFormat", comment: "AccountsProvider: Address not valid error, %@ for address"), address)
			
		case .serverError(let error):
			return ApiServiceError.serverError(error: error.localizedDescription).localized
			
		case .networkError:
			return String.adamantLocalized.sharedErrors.networkError
		}
	}
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
	
	static func messagesFor(address: String) -> [String:AdamantMessage]? {
		switch address {
		case AdamantContacts.adamantBountyWallet.address, AdamantContacts.adamantBountyWallet.name:
			return AdamantContacts.adamantBountyWallet.messages
			
		case AdamantContacts.adamantIco.address, AdamantContacts.adamantIco.name:
			return AdamantContacts.adamantIco.messages
			
		default:
			return nil
		}
	}
	
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
	
	var isReadonly: Bool {
		return true
	}
	
	var avatar: String {
		return "avatar_bots"
	}
	
	var messages: [String:AdamantMessage] {
		switch self {
		case .adamantBountyWallet:
			return ["chats.welcome_message": AdamantMessage.markdownText(NSLocalizedString("Chats.WelcomeMessage", comment: "Known contacts: Adamant welcome message. Markdown supported."))]
			
		case .adamantIco:
			return [
				"chats.preico_message": AdamantMessage.text(NSLocalizedString("Chats.PreIcoMessage", comment: "Known contacts: Adamant pre ICO message")),
				"chats.ico_message": AdamantMessage.markdownText(NSLocalizedString("Chats.IcoMessage", comment: "Known contacts: Adamant ICO message. Markdown supported."))
			]
		}
	}
}
