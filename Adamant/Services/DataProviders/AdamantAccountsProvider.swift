//
//  AdamantAccountsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

private enum Contacts {
	case adamantBountyWallet
	case adamantIco
	
	var name: String {
		switch self {
		case .adamantBountyWallet: return "ADAMANT Bounty Wallet"
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
			return ["chats.welcome_message": NSLocalizedString("Welcome to ADAMANT, the most secure and anonymous messenger. You are credited with bounty tokens, which you can use to get acquainted with the messenger.\nRemember, your security and anonymity is up to you also. Do not follow links you receive, otherwise your IP can be compromised. Do not trust browser extensions. Better to share your ADM address personally, but not using other messengers. Keep your secret passphrase secure. Set a password on your device or logout before leaving.\nLearn more about security and anonymity at https://adamant.im/staysecured/.\n\nDo not reply to this message, it is a system account.", comment: "Known contacts: Adamant welcome message")]
			
		case .adamantIco:
			return [
				"chats.preico_message": NSLocalizedString("You have a possibility to invest in ADAMANT, the most secure and anonymous messenger. Now is a Pre-ICO stage — the most profitable for investors. Learn more on Adamant.im website or in the Whitepaper. To participate just reply to this message and we will assist. We are eager to answer quickly, but sometimes delays for a couple of hours are possible.\nAfter you invest and receive ADM tokens, we recommend to keep them as long as possible. All of unsold tokens during ICO will be distributed among users wallets, adding 5% monthly. Additional info is on Adamant.im website and in the Whitepaper.", comment: "Known contacts: Adamant pre ICO message"),
				"chats.ico_message": NSLocalizedString("You have a possibility to invest in ICO of ADAMANT, the most secure and anonymous messenger. Earlier you participate, better offer you will get. Learn more on Adamant.im website or in the Whitepaper. To invest, go to Wallet→Invest in the ICO, or follow a website page Adamant.im/ico/. If you still have any questions, you can ask them by replying to this message. We are eager to answer quickly, but sometimes delays for a couple of hours are possible.\nAfter you invest and receive ADM tokens, we recommend to keep them as long as possible. All of unsold tokens during ICO will be distributed among users wallets, adding 5% monthly. Additional info is on Adamant.im website and in the Whitepaper.", comment: "Known contacts: Adamant ICO message")
			]
		}
	}
}


class AdamantAccountsProvider: AccountsProvider {
	struct KnownContact {
		let address: String
		let name: String
		let avatar: String?
		let messages: [KnownMessage]?
		
		fileprivate init(contact: Contacts) {
			self.address = contact.address
			self.name = contact.name
			self.avatar = contact.avatar
			self.messages = contact.messages.map({ KnownMessage(key: $0, message: $1) })
		}
	}
	
	struct KnownMessage {
		let key: String
		let message: String
	}
	
	// MARK: Dependencies
	var stack: CoreDataStack!
	var apiService: ApiService!
	
	
	// MARK: Properties
	private let knownContacts: [String:KnownContact]
	
	
	// MARK: Lifecycle
	init() {
		self.knownContacts = [
			Contacts.adamantIco.address: KnownContact(contact: Contacts.adamantIco),
			Contacts.adamantBountyWallet.address: KnownContact(contact: Contacts.adamantBountyWallet)
		]
	}
	
	
	// MARK: Threading
	private let queue = DispatchQueue(label: "im.adamant.accounts.getAccount", qos: .utility, attributes: [.concurrent])
	
	private var requestGroups = [String:DispatchGroup]()
	private let groupsSemaphore = DispatchSemaphore(value: 1)
	
	private func getAccount(byPredicate predicate: NSPredicate, context: NSManagedObjectContext? = nil) -> CoreDataAccount? {
		let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
		request.fetchLimit = 1
		request.predicate = predicate
		
		var acc: CoreDataAccount? = nil
		
		if Thread.isMainThread {
			acc = (try? (context ?? stack.container.viewContext).fetch(request))?.first
		} else {
			DispatchQueue.main.sync {
				acc = (try? (context ?? stack.container.viewContext).fetch(request))?.first
			}
		}
		
		return acc
	}
}


// MARK: - Getting account info from API
extension AdamantAccountsProvider {
	/// Get account info from servier.
	///
	/// - Parameters:
	///   - address: address of an account
	///   - completion: returns Account created in viewContext
	func getAccount(byAddress address: String, completion: @escaping (AccountsProviderResult) -> Void) {
		// Go background, to not to hang threads (especially main) on semaphores and dispatch groups
		queue.async {
			self.groupsSemaphore.wait()
			
			// If there is already request for a this address, wait
			if let group = self.requestGroups[address] {
				self.groupsSemaphore.signal()
				group.wait()
				self.groupsSemaphore.wait()
			}
			
			// Check if there is an account, that we are looking for
			if let account = self.getAccount(byPredicate: NSPredicate(format: "address == %@", address)) {
				self.groupsSemaphore.signal()
				completion(.success(account))
				return
			}
			
			// No, we need to get one from server.
			let group = DispatchGroup()
			self.requestGroups[address] = group
			group.enter()
			self.groupsSemaphore.signal()
			
			self.apiService.getAccount(byAddress: address) { result in
				defer {
					self.groupsSemaphore.wait()
					self.requestGroups.removeValue(forKey: address)
					self.groupsSemaphore.signal()
					group.leave()
				}
				
				switch result {
				case .success(let account):
					let coreAccount = self.createCoreDataAccount(from: account)
					completion(.success(coreAccount))
					
				case .failure(let error):
					switch error {
					case .accountNotFound:
						completion(.notFound)
						
					default:
						completion(.serverError(error))
					}
				}
			}
		}
	}
	
	
	/// Get account info from servier.
	///
	/// - Parameters:
	///   - publicKey: publicKey of an account
	///   - completion: returns Account created in viewContext
	func getAccount(byPublicKey publicKey: String, completion: @escaping (AccountsProviderResult) -> Void) {
		// Go background, to not to hang threads (especially main) on semaphores and dispatch groups
		queue.async {
			self.groupsSemaphore.wait()
			
			// If there is already request for a this address, wait
			if let group = self.requestGroups[publicKey] {
				self.groupsSemaphore.signal()
				group.wait()
				self.groupsSemaphore.wait()
			}
			
			
			// Check account
			if let account = self.getAccount(byPredicate: NSPredicate(format: "publicKey == %@", publicKey)) {
				self.groupsSemaphore.signal()
				completion(.success(account))
				return
			}
			
			// Not found, maybe on server?
			let group = DispatchGroup()
			self.requestGroups[publicKey] = group
			group.enter()
			self.groupsSemaphore.signal()
			
			self.apiService.getAccount(byPublicKey: publicKey) { result in
				defer {
					self.groupsSemaphore.wait()
					self.requestGroups.removeValue(forKey: publicKey)
					self.groupsSemaphore.signal()
					group.leave()
				}
				
				switch result {
				case .success(let account):
					let coreAccount = self.createCoreDataAccount(from: account)
					completion(.success(coreAccount))
					
				case .failure(let error):
					switch error {
					case .accountNotFound:
						completion(.notFound)
						
					default:
						completion(.serverError(error))
					}
				}
			}
		}
	}
	
	private func createCoreDataAccount(from account: Account) -> CoreDataAccount {
		let coreAccount: CoreDataAccount
		if Thread.isMainThread {
			coreAccount = createCoreDataAccount(from: account, context: stack.container.viewContext)
		} else {
			var acc: CoreDataAccount!
			DispatchQueue.main.sync {
				acc = createCoreDataAccount(from: account, context: stack.container.viewContext)
			}
			coreAccount = acc
		}
		
		return coreAccount
	}
	
	private func createCoreDataAccount(from account: Account, context: NSManagedObjectContext) -> CoreDataAccount {
		let coreAccount = CoreDataAccount(entity: CoreDataAccount.entity(), insertInto: context)
		coreAccount.address = account.address
		coreAccount.publicKey = account.publicKey
		
		if let acc = knownContacts[account.address] {
			coreAccount.name = acc.name
			coreAccount.avatar = acc.avatar
			if let messages = acc.messages {
				coreAccount.knownMessages = messages.reduce(into: [String:String](), { (result, message) in
					result[message.key] = message.message
				})
			}
		}
		
		return coreAccount
	}
}
