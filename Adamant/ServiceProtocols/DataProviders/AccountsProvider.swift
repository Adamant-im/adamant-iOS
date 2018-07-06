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
struct SystemMessage {
	let message: AdamantMessage
	let silentNotification: Bool
}

enum AdamantContacts {
	static let systemAddresses: [String] = {
		return [AdamantContacts.adamantIco.name, AdamantContacts.adamantBountyWallet.name]
	}()
	
	static func messagesFor(address: String) -> [String:SystemMessage]? {
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
	case iosSupport
	
	var name: String {
		switch self {
		case .adamantBountyWallet: return "ADAMANT Bounty"
		case .adamantIco: return NSLocalizedString("Accounts.AdamantTokens", comment: "System accounts: ADAMANT Tokens")
		case .iosSupport: return NSLocalizedString("Accounts.iOSSupport", comment: "System accounts: ADAMANT iOS Support")
		}
	}
	
	var address: String {
		switch self {
		case .adamantBountyWallet: return AdamantResources.contacts.adamantBountyWallet
		case .adamantIco: return AdamantResources.contacts.adamantIco
		case .iosSupport: return AdamantResources.contacts.iosSupport
		}
	}
	
	var isReadonly: Bool {
		switch self {
		case .adamantBountyWallet, .adamantIco: return true
		case .iosSupport: return false
		}
	}
	
	var isHidden: Bool {
		switch self {
		case .adamantBountyWallet: return true
		case .adamantIco, .iosSupport: return false
		}
	}
	
	var avatar: String {
		return "avatar_bots"
	}
	
	var messages: [String: SystemMessage] {
		switch self {
		case .adamantBountyWallet:
			return ["chats.welcome_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.WelcomeMessage", comment: "Known contacts: Adamant welcome message. Markdown supported.")),
														   silentNotification: true)]
			
		case .adamantIco:
			return [
				"chats.preico_message": SystemMessage(message: AdamantMessage.text(NSLocalizedString("Chats.PreIcoMessage", comment: "Known contacts: Adamant pre ICO message")),
													  silentNotification: true),
				"chats.ico_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.IcoMessage", comment: "Known contacts: Adamant ICO message. Markdown supported.")),
												   silentNotification: true)
			]
			
		case .iosSupport:
			return [:]
		}
	}
}
