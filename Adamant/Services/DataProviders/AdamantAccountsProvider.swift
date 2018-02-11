//
//  AdamantAccountsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

class AdamantAccountsProvider: AccountsProvider {
	struct KnownContact: Codable {
		let address: String
		let name: String
		let avatar: String?
		let messages: [KnownMessage]?
	}
	
	struct KnownMessage: Codable {
		let key: String
		let message: String
	}
	
	// MARK: Dependencies
	var stack: CoreDataStack!
	var apiService: ApiService!
	
	
	// MARK: Properties
	private let knownContacts: [String:KnownContact]
	
	
	// MARK: Lifecycle
	init(contactsJsonUrl url: URL) throws {
		let raw = try Data(contentsOf: url)
		let knownContacts = try JSONDecoder().decode([KnownContact].self, from: raw)
		
		self.knownContacts = knownContacts.reduce(into: [String:KnownContact](), { (result, contact) in
			result[contact.address] = contact
		})
	}
	
	
	// MARK: Threading
	private let queue = DispatchQueue(label: "im.adamant.accounts.getAccount", qos: .utility, attributes: [.concurrent])
	
	private var requestGroups = [String:DispatchGroup]()
	private let groupsSemaphore = DispatchSemaphore(value: 1)
	
	private func getAccount(byPredicate predicate: NSPredicate, context: NSManagedObjectContext? = nil) -> CoreDataAccount? {
		let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
		request.fetchLimit = 1
		request.predicate = predicate
		
		return (try? (context ?? stack.container.viewContext).fetch(request))?.first
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
