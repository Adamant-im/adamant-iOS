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
	case serverError(Error)
}

protocol AccountsProvider {
	
	/// Search for fetched account, if not found, asks server for account.
	///
	/// - Returns: Account, if found, created in main viewContext
	func getAccount(byAddress address: String, completion: @escaping (AccountsProviderResult) -> Void)
	
	/// Search for fetched account, if not found, asks server for account.
	///
	/// - Returns: Account, if found, created in main viewContext
	func getAccount(byPublicKey publicKey: String, completion: @escaping (AccountsProviderResult) -> Void)
}
