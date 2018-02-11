//
//  TransfersProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

enum TransfersProviderError: Error {
	case notLogged
	case serverError(Error)
	case accountNotFound(String)
}

enum TransfersProviderResult {
	case success
	case error(TransfersProviderError)
}

extension Notification.Name {
	/// userInfo contains 'newTransactions' element. See AdamantUserInfoKey.TransfersProvider
	static let adamantTransfersServiceNewTransactions = Notification.Name("adamantTransfersServiceNewTransactions")
	
	/// userInfo contains newState element. See AdamantUserInfoKey.TransfersProvider
	static let adamantTransfersServiceStateChanged = Notification.Name("adamantTransfersServiceStateChanged")
}

extension AdamantUserInfoKey {
	struct TransfersProvider {
		/// New provider state
		static let newState = "transfersNewState"
		
		/// Previous provider state, if avaible
		static let prevState = "transfersPrevState"
		
		// New received transactions
		static let newTransactions = "transfersNewTransactions"
		
		private init() {}
	}
}

protocol TransfersProvider: DataProvider {
	func transfersController() -> NSFetchedResultsController<TransferTransaction>
	
	func transferFunds(toAddress recipient: String, amount: Decimal, completion: @escaping (TransfersProviderResult) -> Void)
}
