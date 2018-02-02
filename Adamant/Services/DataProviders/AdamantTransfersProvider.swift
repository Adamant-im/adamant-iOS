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
	private(set) var status: Status = .empty
	private let processingQueue = DispatchQueue(label: "im.Adamant.processing.transfers", qos: .utility, attributes: [.concurrent])
}


// MARK: - DataProvider
extension AdamantTransfersProvider {
	func reload() {
		reset(notify: false)
		
		update()
	}
	
	func update() {
		if status == .updating {
			return
		}
		
		let prevStatus = status
		status = .updating
		
		guard let address = accountService.account?.address else {
			self.status = .failedToUpdate(TransfersProviderError.notLogged)
			NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceStatusChanged, object: self.status)
			return
		}
		
		apiService.getTransactions(forAccount: address, type: .send) { (transactions, error) in
			guard let transactions = transactions else {
				self.status = .failedToUpdate(error!)
				NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceStatusChanged, object: self.status)
				return
			}
			
			guard transactions.count > 0 else {
				self.status = .upToDate
				if prevStatus != self.status {
					NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceStatusChanged, object: self.status)
				}
				return
			}
			
			self.processingQueue.async {
				self.processRawTransactions(transactions, currentAddress: address) { result in
					switch result {
					case .success(let total):
						self.status = .upToDate
						
						if prevStatus != self.status {
							NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceStatusChanged, object: self.status)
						} else if total > 0 {
							NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceNewTransactions, object: total)
						}
						
					case .error(let error):
						self.status = .failedToUpdate(error)
						NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceStatusChanged, object: self.status)
						
					case .accountNotFound(let key):
						self.status = .failedToUpdate(TransfersProviderError.accountNotFound(key))
						NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceStatusChanged, object: self.status)
					}
				}
			}
		}
	}
	
	func reset() {
		reset(notify: true)
	}
	
	private func reset(notify: Bool) {
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		if let result = try? stack.container.viewContext.fetch(request) {
			if result.count > 0 {
				for obj in result {
					stack.container.viewContext.delete(obj)
				}
				try? stack.container.viewContext.save()
			}
		}
		
		let prevStatus = status
		status = .empty
		
		if notify && prevStatus != status {
			NotificationCenter.default.post(name: Notification.Name.adamantTransfersServiceStatusChanged, object: nil)
		}
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
	
	func transferFunds(toAddress recipient: String, amount: Decimal, completionHandler: @escaping (TransfersProviderResult) -> Void) {
		guard let senderAddress = accountService.account?.address, let keypair = accountService.keypair else {
			completionHandler(.error(.notLogged))
			return
		}
		
		apiService.transferFunds(sender: senderAddress, recipient: recipient, amount: (amount as NSDecimalNumber).uintValue, keypair: keypair) { (success, error) in
			if success {
				completionHandler(.success)
			} else {
				completionHandler(.error(.serverError(error!)))
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
	
	private func processRawTransactions(_ transactions: [Transaction], currentAddress address: String, completionHandler: @escaping (ProcessingResult) -> Void) {
		// MARK: 0. Transactions?
		guard transactions.count > 0 else {
			completionHandler(.success(new: 0))
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
			accountsProvider.getAccount(byPublicKey: key, completionHandler: { result in
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
			completionHandler(err)
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
		for t in transactions {
			let transfer = TransferTransaction(entity: TransferTransaction.entity(), insertInto: context)
			transfer.amount = Decimal(t.amount) as NSDecimalNumber
			transfer.date = t.date as NSDate
			transfer.fee = Decimal(t.fee) as NSDecimalNumber
			transfer.height = Int64(t.height)
			transfer.recipientId = t.recipientId
			transfer.senderId = t.senderId
			transfer.transactionId = String(t.id)
			transfer.type = Int16(t.type.rawValue)
			
			transfer.isOutgoing = t.senderId == address
			
			if let partnerKey = transfer.isOutgoing ? t.recipientPublicKey : t.senderPublicKey {
				transfer.partner = partners[partnerKey]
			}
			
			totalTransactions += 1
		}
		
		// MARK: 4. Dump transactions to viewContext
		if context.hasChanges {
			do {
				try context.save()
				completionHandler(.success(new: totalTransactions))
			} catch {
				completionHandler(.error(error))
			}
		} else {
			completionHandler(.success(new: 0))
		}
	}
}
