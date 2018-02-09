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
	// MARK: Dependencies
	var stack: CoreDataStack!
	var apiService: ApiService!
	
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
	///   - completionHandler: returns Account created in viewContext
	func getAccount(byAddress address: String, completionHandler: @escaping (AccountsProviderResult) -> Void) {
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
				completionHandler(.success(account))
				return
			}
			
			// No, we need to get one from server.
			let group = DispatchGroup()
			self.requestGroups[address] = group
			group.enter()
			self.groupsSemaphore.signal()
			
			self.apiService.getAccount(byAddress: address) { (account, error) in
				defer {
					self.groupsSemaphore.wait()
					self.requestGroups.removeValue(forKey: address)
					self.groupsSemaphore.signal()
					group.leave()
				}
				
				if let error = error {
					completionHandler(.serverError(error))
					return
				}
				
				guard let account = account else {
					completionHandler(.notFound)
					return
				}
				
				let coreAccount = self.createCoreDataAccount(from: account)
				completionHandler(.success(coreAccount))
			}
		}
	}
	
	
	/// Get account info from servier.
	///
	/// - Parameters:
	///   - publicKey: publicKey of an account
	///   - completionHandler: returns Account created in viewContext
	func getAccount(byPublicKey publicKey: String, completionHandler: @escaping (AccountsProviderResult) -> Void) {
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
				completionHandler(.success(account))
				return
			}
			
			// Not found, maybe on server?
			let group = DispatchGroup()
			self.requestGroups[publicKey] = group
			group.enter()
			self.groupsSemaphore.signal()
			
			self.apiService.getAccount(byPublicKey: publicKey) { (account, error) in
				defer {
					self.groupsSemaphore.wait()
					self.requestGroups.removeValue(forKey: publicKey)
					self.groupsSemaphore.signal()
					group.leave()
				}
				
				if let error = error {
					completionHandler(.serverError(error))
					return
				}
				
				guard let account = account else {
					completionHandler(.notFound)
					return
				}
				
				let coreAccount = self.createCoreDataAccount(from: account)
				completionHandler(.success(coreAccount))
			}
		}
	}
	
	private func createCoreDataAccount(from account: Account) -> CoreDataAccount {
		let coreAccount: CoreDataAccount
		if Thread.isMainThread {
			coreAccount = CoreDataAccount(entity: CoreDataAccount.entity(), insertInto: stack.container.viewContext)
			coreAccount.address = account.address
			coreAccount.publicKey = account.publicKey
		} else {
			var acc: CoreDataAccount!
			DispatchQueue.main.sync {
				acc = CoreDataAccount(entity: CoreDataAccount.entity(), insertInto: stack.container.viewContext)
				acc.address = account.address
				acc.publicKey = account.publicKey
			}
			coreAccount = acc
		}
		
		return coreAccount
	}
}
