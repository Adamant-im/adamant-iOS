//
//  AdamantTransfersProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

class AdamantTransfersProvider: TransfersProvider {
	// MARK: Dependencies
	var apiService: ApiService!
	var stack: CoreDataStack!
	var accountService: AccountService!
	var accountsProvider: AccountsProvider!
	
	// MARK: Properties
	var transferFee: Decimal = Decimal(sign: .plus, exponent: -1, significand: 5)
	
	private(set) var state: State = .empty
	private var lastHeight: UInt64?
	
	private let processingQueue = DispatchQueue(label: "im.Adamant.processing.transfers", qos: .utility, attributes: [.concurrent])
	private let stateSemaphore = DispatchSemaphore(value: 1)
	
	// MARK: Tools
	private func postNotification(_ name: Notification.Name, userInfo: [AnyHashable : Any]? = nil) {
		NotificationCenter.default.post(name: name, object: nil, userInfo: userInfo)
	}
	
	/// Free stateSemaphore before calling this method, or you will deadlock.
	private func setState(_ state: State, previous prevState: State, notify: Bool = true) {
		stateSemaphore.wait()
		self.state = state
		stateSemaphore.signal()
		
		if notify {
			switch prevState {
			case .failedToUpdate(_):
				NotificationCenter.default.post(name: .adamantTransfersServiceStateChanged, object: nil, userInfo: [AdamantUserInfoKey.TransfersProvider.newState: state,
																													 AdamantUserInfoKey.TransfersProvider.prevState: prevState])
				
			default:
				if prevState != self.state {
					NotificationCenter.default.post(name: .adamantTransfersServiceStateChanged, object: nil, userInfo: [AdamantUserInfoKey.TransfersProvider.newState: state,
																														 AdamantUserInfoKey.TransfersProvider.prevState: prevState])
				}
			}
		}
	}
}


// MARK: - DataProvider
extension AdamantTransfersProvider {
	func reload() {
		reset(notify: false)
		
		update()
	}
	
	func update() {
		stateSemaphore.wait()
		if state == .updating {
			return
		}
		
		let prevState = state
		state = .updating
		stateSemaphore.signal()
		
		guard let address = accountService.account?.address else {
			self.setState(.failedToUpdate(TransfersProviderError.notLogged), previous: prevState)
			return
		}
		
		apiService.getTransactions(forAccount: address, type: .send, fromHeight: lastHeight) { result in
			switch result {
			case .success(let transactions):
				guard transactions.count > 0 else {
					self.setState(.upToDate, previous: prevState)
					return
				}
				
				self.processingQueue.async {
					self.processRawTransactions(transactions, currentAddress: address) { result in
						switch result {
						case .success(let total):
							self.setState(.upToDate, previous: prevState)
							if total > 0 {
								self.postNotification(.adamantTransfersServiceNewTransactions, userInfo: [AdamantUserInfoKey.TransfersProvider.newTransactions: total])
							}
							
						case .error(let error):
							self.setState(.failedToUpdate(error), previous: prevState)
							
						case .accountNotFound(let key):
							self.setState(.failedToUpdate(TransfersProviderError.accountNotFound(key)), previous: prevState)
						}
					}
				}
				
			case .failure(let error):
				self.setState(.failedToUpdate(error), previous: prevState)
			}
		}
	}
	
	func reset() {
		reset(notify: true)
	}
	
	private func reset(notify: Bool) {
		let prevState = self.state
		setState(.updating, previous: prevState, notify: false)
		lastHeight = nil
		
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.parent = stack.container.viewContext
		
		if let result = try? context.fetch(request) {
			for obj in result {
				context.delete(obj)
			}
			
			try? context.save()
		}
		
		setState(.empty, previous: prevState, notify: notify)
	}
}


// MARK: - TransfersProvider
extension AdamantTransfersProvider {
	func transfersController() -> NSFetchedResultsController<TransferTransaction> {
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		try! controller.performFetch()
		return controller
	}
	
	func transferFunds(toAddress recipient: String, amount: Decimal, completion: @escaping (TransfersProviderResult) -> Void) {
		guard let senderAddress = accountService.account?.address, let keypair = accountService.keypair else {
			completion(.error(.notLogged))
			return
		}
		
		apiService.transferFunds(sender: senderAddress, recipient: recipient, amount: amount, keypair: keypair) { result in
			switch result {
			case .success(_):
				completion(.success)
				
			case .failure(let error):
				completion(.error(.serverError(error)))
			}
		}
	}
}


// MARK: - Data processing
extension AdamantTransfersProvider {
	private enum ProcessingResult {
		case success(new: Int)
		case accountNotFound(publicKey: String)
		case error(Error)
	}
	
	private func processRawTransactions(_ transactions: [Transaction], currentAddress address: String, completion: @escaping (ProcessingResult) -> Void) {
		// MARK: 0. Transactions?
		guard transactions.count > 0 else {
			completion(.success(new: 0))
			return
		}
		
		// MARK: 1. Collect all partners
		var partnersKeys: Set<String> = []
		
		for t in transactions {
			let isOutgoing = t.senderId == address
			guard let partersKey = isOutgoing ? t.recipientPublicKey : t.senderPublicKey else {
				continue
			}
			
			partnersKeys.insert(partersKey)
		}
		
		// MARK: 2. Let AccountProvider get all partners from server.
		let partnersGroup = DispatchGroup()
		var errors: [ProcessingResult] = []
		for key in partnersKeys {
			partnersGroup.enter()
			accountsProvider.getAccount(byPublicKey: key, completion: { result in
				defer {
					partnersGroup.leave()
				}
				
				switch result {
				case .success(_):
					break
					
				case .notFound:
					errors.append(ProcessingResult.accountNotFound(publicKey: key))
					
				case .serverError(let error):
					errors.append(ProcessingResult.error(error))
				}
			})
		}
		
		partnersGroup.wait()
		
		// MARK: 2.5. If we have any errors - drop processing.
		if let err = errors.first {
			completion(err)
			return
		}
		
		
		// MARK: 3. Create private context, and process transactions
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.parent = self.stack.container.viewContext
		
		var partners: [String:CoreDataAccount] = [:]
		for key in partnersKeys {
			let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
			request.predicate = NSPredicate(format: "publicKey == %@", key)
			request.fetchLimit = 1
			if let partner = (try? context.fetch(request))?.first {
				partners[key] = partner
			}
		}
		
		var totalTransactions = 0
		var height: Int64 = 0
		for t in transactions {
			let transfer = TransferTransaction(entity: TransferTransaction.entity(), insertInto: context)
			transfer.amount = t.amount as NSDecimalNumber
			transfer.date = t.date as NSDate
			transfer.fee = t.fee as NSDecimalNumber
			transfer.height = Int64(t.height)
			transfer.recipientId = t.recipientId
			transfer.senderId = t.senderId
			transfer.transactionId = String(t.id)
			transfer.type = Int16(t.type.rawValue)
			transfer.blockId = t.blockId
			transfer.confirmations = t.confirmations
			
			transfer.isOutgoing = t.senderId == address
			
			if let partnerKey = transfer.isOutgoing ? t.recipientPublicKey : t.senderPublicKey {
				transfer.partner = partners[partnerKey]
			}
			
			if t.height > height {
				height = t.height
			}
			
			totalTransactions += 1
		}
		
		// MARK: 4. Check lastHeight
		// API returns transactions from lastHeight INCLUDING transaction with height == lastHeight, so +1
		if height > 0 {
			let uH = UInt64(height + 1)
			
			if let lastHeight = lastHeight {
				if lastHeight < uH {
					self.lastHeight = uH
				}
			} else {
				self.lastHeight = uH
			}
		}
		
		// MARK: 5. Dump transactions to viewContext
		if context.hasChanges {
			do {
				try context.save()
				completion(.success(new: totalTransactions))
			} catch {
				completion(.error(error))
			}
		} else {
			completion(.success(new: 0))
		}
	}
}
