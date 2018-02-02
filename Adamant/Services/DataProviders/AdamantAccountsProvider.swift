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
	
	func getAccount(byPredicate predicate: NSPredicate, context: NSManagedObjectContext? = nil) -> CoreDataAccount? {
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
		if let account = getAccount(byPredicate: NSPredicate(format: "address == %@", address)) {
			completionHandler(.success(account))
			return
		}
		
		apiService.getAccount(byAddress: address) { (account, error) in
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
	
	
	/// Get account info from servier.
	///
	/// - Parameters:
	///   - publicKey: publicKey of an account
	///   - completionHandler: returns Account created in viewContext
	func getAccount(byPublicKey publicKey: String, completionHandler: @escaping (AccountsProviderResult) -> Void) {
		if let account = getAccount(byPredicate: NSPredicate(format: "publicKey == %@", publicKey)) {
			completionHandler(.success(account))
			return
		}
		
		apiService.getAccount(byPublicKey: publicKey) { (account, error) in
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
