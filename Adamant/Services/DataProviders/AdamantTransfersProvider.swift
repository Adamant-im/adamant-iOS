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
	var securedStore: SecuredStore!
	
	// MARK: Properties
	var transferFee: Decimal = Decimal(sign: .plus, exponent: -1, significand: 5)
	
	private(set) var state: State = .empty
	private(set) var receivedLastHeight: Int64?
	private(set) var readedLastHeight: Int64?
	
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
	
	
	// MARK: Lifecycle
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedIn, object: nil, queue: nil) { [weak self] notification in
			guard let store = self?.securedStore else {
				return
			}
			
			guard let loggedAddress = notification.userInfo?[AdamantUserInfoKey.AccountService.loggedAccountAddress] as? String else {
				store.remove(StoreKey.transfersProvider.address)
				store.remove(StoreKey.transfersProvider.receivedLastHeight)
				store.remove(StoreKey.transfersProvider.readedLastHeight)
				return
			}
			
			if let savedAddress = store.get(StoreKey.transfersProvider.address), savedAddress == loggedAddress {
				if let raw = store.get(StoreKey.transfersProvider.readedLastHeight), let h = Int64(raw) {
					self?.readedLastHeight = h
				}
			} else {
				store.remove(StoreKey.transfersProvider.address)
				store.remove(StoreKey.transfersProvider.receivedLastHeight)
				store.remove(StoreKey.transfersProvider.readedLastHeight)
			}
			
			self?.update()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.receivedLastHeight = nil
			self?.readedLastHeight = nil
			
			if let prevState = self?.state {
				self?.setState(.empty, previous: prevState)
			}
			
			if let store = self?.securedStore {
				store.remove(StoreKey.transfersProvider.address)
				store.remove(StoreKey.transfersProvider.receivedLastHeight)
				store.remove(StoreKey.transfersProvider.readedLastHeight)
			}
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
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
			stateSemaphore.signal()
			return
		}
		
		let prevState = state
		state = .updating
		stateSemaphore.signal()
		
		guard let address = accountService.account?.address else {
			self.setState(.failedToUpdate(TransfersProviderError.notLogged), previous: prevState)
			return
		}
		
		apiService.getTransactions(forAccount: address, type: .send, fromHeight: receivedLastHeight) { result in
			switch result {
			case .success(let transactions):
				guard transactions.count > 0 else {
					self.setState(.upToDate, previous: prevState)
					return
				}
				
				self.processingQueue.async {
					self.processRawTransactions(transactions, currentAddress: address) { [weak self] result in
						switch result {
						case .success(let total):
							self?.setState(.upToDate, previous: prevState)
							if total > 0 {
								self?.postNotification(.adamantTransfersServiceNewTransactions, userInfo: [AdamantUserInfoKey.TransfersProvider.newTransactions: total])
							}
							
							if let h = self?.receivedLastHeight {
								self?.readedLastHeight = h
							} else {
								self?.readedLastHeight = 0
							}
							
						case .error(let error):
							self?.setState(.failedToUpdate(error), previous: prevState)
							
						case .accountNotFound(let key):
							self?.setState(.failedToUpdate(TransfersProviderError.accountNotFound(key)), previous: prevState)
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
		receivedLastHeight = nil
		readedLastHeight = nil
		securedStore.remove(StoreKey.transfersProvider.receivedLastHeight)
		securedStore.remove(StoreKey.transfersProvider.readedLastHeight)
		
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
	// MARK: Controllers
	func transfersController() -> NSFetchedResultsController<TransferTransaction> {
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false),
								   NSSortDescriptor(key: "transactionId", ascending: false)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return controller
	}
	
	func transfersController(for account: CoreDataAccount) -> NSFetchedResultsController<TransferTransaction> {
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false),
								   NSSortDescriptor(key: "transactionId", ascending: false)]
		request.predicate = NSPredicate(format: "partner = %@", account)
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		try! controller.performFetch()
		return controller
	}
	
	func unreadTransfersController() -> NSFetchedResultsController<TransferTransaction> {
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		request.predicate = NSPredicate(format: "isUnread == true")
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false),
								   NSSortDescriptor(key: "transactionId", ascending: false)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return controller
	}
	
	// MARK: Sending Funds
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
		case accountNotFound(address: String)
		case error(Error)
	}
	
	private func processRawTransactions(_ transactions: [Transaction],
										currentAddress address: String,
										completion: @escaping (ProcessingResult) -> Void) {
		// MARK: 0. Transactions?
		guard transactions.count > 0 else {
			completion(.success(new: 0))
			return
		}
		
		// MARK: 1. Collect all partners
		var partnerIds: Set<String> = []
		
		for t in transactions {
			if t.senderId == address {
				partnerIds.insert(t.recipientId)
			} else {
				partnerIds.insert(t.senderId)
			}
		}
		
		// MARK: 2. Let AccountProvider get all partners from server.
		let partnersGroup = DispatchGroup()
		var errors: [ProcessingResult] = []
		for id in partnerIds {
			partnersGroup.enter()
			accountsProvider.getAccount(byAddress: id, completion: { result in
				defer {
					partnersGroup.leave()
				}
				
				switch result {
				case .success(_):
					break
					
				case .notFound:
					errors.append(ProcessingResult.accountNotFound(address: id))
					
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
		for id in partnerIds {
			let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
			request.predicate = NSPredicate(format: "address == %@", id)
			request.fetchLimit = 1
			if let partner = (try? context.fetch(request))?.first {
				partners[id] = partner
			}
		}
		
		var transfers = [TransferTransaction]()
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
			let partnerId = transfer.isOutgoing ? t.recipientId : t.senderId
			
			if let partner = partners[partnerId] {
				transfer.partner = partner
				transfer.chatroom = partner.chatroom
			}
			
			if t.height > height {
				height = t.height
			}
			
			transfers.append(transfer)
		}
		
		
		// MARK: 4. Check lastHeight
		// API returns transactions from lastHeight INCLUDING transaction with height == lastHeight, so +1
		if height > 0 {
			let uH = Int64(height + 1)
			
			if let lastHeight = receivedLastHeight {
				if lastHeight < uH {
					self.receivedLastHeight = uH
				}
			} else {
				self.receivedLastHeight = uH
			}
		}
		
		// MARK: 5. Unread transactions
		if let unreadedHeight = readedLastHeight {
			let unreadTransactions = transfers.filter { $0.height > unreadedHeight }
			let chatrooms = Dictionary.init(grouping: unreadTransactions, by: ({ (t: TransferTransaction) -> Chatroom in t.chatroom!}))
			
			for (chatroom, trs) in chatrooms {
				chatroom.hasUnreadMessages = true
				trs.forEach { $0.isUnread = true }
			}
			
			transfers.filter({$0.height > unreadedHeight}).forEach({$0.isUnread = true})
			
			readedLastHeight = self.receivedLastHeight
		}
		
		if let h = self.receivedLastHeight {
			securedStore.set(String(h), for: StoreKey.transfersProvider.receivedLastHeight)
		}
		
		if let h = self.readedLastHeight {
			securedStore.set(String(h), for: StoreKey.transfersProvider.readedLastHeight)
		}
		
		// MARK: 6. Dump transactions to viewContext
		if context.hasChanges {
			do {
				try context.save()
				
				// MARK: 7. Update lastTransactions
				let viewContextChatrooms = Set<Chatroom>(transfers.compactMap { $0.chatroom }).compactMap { self.stack.container.viewContext.object(with: $0.objectID) as? Chatroom }
				DispatchQueue.main.async {
					viewContextChatrooms.forEach { $0.updateLastTransaction() }
				}
				
				completion(.success(new: transfers.count))
			} catch {
				completion(.error(error))
			}
		} else {
			completion(.success(new: 0))
		}
	}
}
