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
	
	/// Notification object: amount of new transactions (Int)
	static let adamantTransfersServiceNewTransactions = Notification.Name("adamantTransfersServiceNewTransactions")
	
	/// Notification object: new DataProvider.Status
	static let adamantTransfersServiceStatusChanged = Notification.Name("adamantTransfersServiceStatusChanged")
}

protocol TransfersProvider: DataProvider {
	func transfersController() -> NSFetchedResultsController<TransferTransaction>
	
	func transferFunds(toAddress recipient: String, amount: Decimal, completionHandler: @escaping (TransfersProviderResult) -> Void)
}
