//
//  AdamantChatsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

class AdamantChatsProvider: ChatsProvider {
	// MARK: Dependencies
	var accountService: AccountService!
	var apiService: ApiService!
	var stack: CoreDataStack!
	var adamantCore: AdamantCore!
	var contactsService: ContactsService!
	var accountsProvider: AccountsProvider!
	
	// MARK: Properties
	private(set) var state: State = .empty
	private(set) var lastHeight: Int?
	private let apiTransactions = 100
	private var unconfirmedTransactions: [UInt:ChatTransaction] = [:]
	
	private let processingQueue = DispatchQueue(label: "im.adamant.processing.chat", qos: .utility, attributes: [.concurrent])
	private let unconfirmedsSemaphore = DispatchSemaphore(value: 1)
	private let chatroomsSemaphore = DispatchSemaphore(value: 1)
	
	// MARK: Tools
	private func setState(_ state: State, previous prevState: State, notify: Bool = true) {
		self.state = state
		
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
extension AdamantChatsProvider {
	func reload() {
		reset(notify: false)
		update()
	}
	
	func reset() {
		reset(notify: true)
	}
	
	private func reset(notify: Bool) {
		lastHeight = nil
	}
	
	func update() {
		// MARK: 1. Check state
		switch state {
		case .updating:
			return
			
		case .empty: break
		case .upToDate: break
		case .failedToUpdate(_): break
		}
		
		// MARK: 2. Prepare
		let prevState = state
		
		guard let address = accountService.account?.address else {
			setState(.failedToUpdate(ChatsProviderError.notLogged), previous: prevState)
			return
		}
		
		state = .updating
		
		// MARK: 3. Get transactions
		let processingGroup = DispatchGroup()
		getTransactions(address: address, height: lastHeight, offset: nil, dispatchGroup: processingGroup, parentContext: stack.container.viewContext)
		
		// MARK: 4. Check
		processingGroup.notify(queue: DispatchQueue.global(qos: .utility)) {
			switch self.state {
			case .failedToUpdate(_):
				break
				
			default:
				self.setState(.upToDate, previous: prevState)
			}
		}
	}
}


// MARK: - Getting messages
extension AdamantChatsProvider {
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>? {
		let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		do {
			try controller.performFetch()
			return controller
		} catch {
			print("Error fetching request: \(error)")
			return nil
		}
	}
	
	func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction>? {
		guard chatroom.managedObjectContext == stack.container.viewContext else {
			return nil
		}
		
		let request: NSFetchRequest<ChatTransaction> = NSFetchRequest(entityName: ChatTransaction.entityName)
		request.predicate = NSPredicate(format: "chatroom = %@", chatroom)
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		do {
			try controller.performFetch()
			return controller
		} catch {
			print("Error fetching request: \(error)")
			return nil
		}
	}
	
	func chatroomWith(_ account: CoreDataAccount) -> Chatroom {
		var chatroom: Chatroom! = nil
		if Thread.isMainThread {
			chatroom = chatroomWith(account, context: stack.container.viewContext)
		} else {
			DispatchQueue.main.sync {
				chatroom = chatroomWith(account, context: stack.container.viewContext)
			}
		}
		
		return chatroom
	}
	
	private func chatroomWith(_ account: CoreDataAccount, context: NSManagedObjectContext) -> Chatroom {
		let request = NSFetchRequest<Chatroom>(entityName: Chatroom.entityName)
		request.fetchLimit = 1
		request.predicate = NSPredicate(format: "partner", account)
		
		if let chatroom = (try? context.fetch(request))?.first {
			return chatroom
		}
		
		let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		chatroom.partner = account
		chatroom.partnerAddress = account.address
		return chatroom
	}
}


// MARK: - Processing
extension AdamantChatsProvider {
	/// Get new transactions
	///
	/// - Parameters:
	///   - account: for account
	///   - height: last message height. Minimum == 1 !!!
	///   - offset: offset, if greater than 100
	/// - Returns: ammount of new messages was added
	private func getTransactions(address: String, height: Int?, offset: Int?, dispatchGroup: DispatchGroup, parentContext: NSManagedObjectContext) {
		// Enter 1
		dispatchGroup.enter()
		
		// MARK: 1. Get new transactions
		apiService.getChatTransactions(account: address, height: height, offset: offset) { (transactions, error) in
			defer {
				// Leave 1
				dispatchGroup.leave()
			}
			
			// MARK: 2. Check for errors
			guard let transactions = transactions else {
				if let error = error {
					self.setState(.failedToUpdate(error), previous: .updating)
				}
				return
			}
			
			// MARK: 3. Process transactions in background
			// Enter 2
			dispatchGroup.enter()
			self.processingQueue.async {
				defer {
					// Leave 2
					dispatchGroup.leave()
				}
				
				self.process(chatTransactions: transactions)
			}
			
			// MARK: 4. Get more transactions
			if transactions.count == self.apiTransactions {
				let newOffset: Int
				if let offset = offset {
					newOffset = offset + self.apiTransactions
				} else {
					newOffset = self.apiTransactions
				}
				
				self.getTransactions(address: address, height: height, offset: newOffset, dispatchGroup: dispatchGroup, parentContext: parentContext)
			}
		}
	}
	
	private func process(chatTransactions: [Transaction]) {
		guard let currentAddress = accountService.account?.address, let privateKey = accountService.keypair?.privateKey else {
			// TODO: Log error
			return
		}
		
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		
		// MARK: 1. Gather partner keys
		var partnerAddresses: Set<String> = []
		
		for transaction in chatTransactions {
			let isOutgoingMessage = transaction.senderId == currentAddress
			let partner = isOutgoingMessage ? transaction.recipientId : transaction.senderId
			
			partnerAddresses.insert(partner)
		}
		
		// MARK: 2. Gather Accounts
		var partners: [String:CoreDataAccount] = [:]
		
		let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
		request.fetchLimit = partners.count
		let predicates = partnerAddresses.map { NSPredicate(format: "address = %@", $0) }
		request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
		
		if let results = try? privateContext.fetch(request) {
			for result in results {
				if let address = result.address {
					partners[address] = result
				}
			}
		}
		
		// MARK: 2.5 Get accounts, that we did not found.
		if partners.count != partnerAddresses.count {
			let notFound = partnerAddresses.subtracting(partners.keys)
			var objectIds = [String:NSManagedObjectID]()
			let semaphore = DispatchSemaphore(value: 1)
			let keysGroup = DispatchGroup()
			for address in notFound {
				keysGroup.enter() // Enter 1
				
				accountsProvider.getAccount(byAddress: address) { result in
					defer {
						keysGroup.leave() // Exit 1
					}
					
					if case let .success(account) = result {
						semaphore.wait()
						objectIds[address] = account.objectID
						semaphore.signal()
					}
				}
			}
			
			keysGroup.wait()
			
			for (address, id) in objectIds {
				if let account = privateContext.object(with: id) as? CoreDataAccount {
					partners[address] = account
				}
			}
		}
		
		if partners.count != partnerAddresses.count {
			// TODO: Log this strange thing
			print("Failed to get all accounts: Needed keys:\n\(partnerAddresses.map { "\($0)\n" })\nFounded Addresses: \(partners.keys.joined(separator: "\n"))")
		}
		
		
		// MARK: 3. Process Transactions, group them by partner
		var partnersChats = [String: Set<ChatTransaction>]()
		var lastHeight: Int64 = 0
		
		for transaction in chatTransactions {
			unconfirmedsSemaphore.wait()
			if unconfirmedTransactions.count > 0, let unconfirmed = unconfirmedTransactions[transaction.id] {
				confirmTransaction(unconfirmed, id: transaction.id, height: transaction.height)
				continue
			}
			unconfirmedsSemaphore.signal()
			
			let isOutgoing = transaction.senderId == currentAddress
			let publicKey: String
			if isOutgoing {
				publicKey = partners[transaction.recipientId]?.publicKey ?? ""
			} else {
				publicKey = transaction.senderPublicKey
			}
			
			if let chatTransaction = chatTransaction(from: transaction, isOutgoing: isOutgoing, publicKey: publicKey, privateKey: privateKey, context: privateContext) {
				if lastHeight < chatTransaction.height {
					lastHeight = chatTransaction.height
				}
				
				if let partner = chatTransaction.isOutgoing ? chatTransaction.recipientId : chatTransaction.senderId {
					if partnersChats[partner] == nil {
						partnersChats[partner] = Set<ChatTransaction>()
					}
					
					partnersChats[partner]!.insert(chatTransaction)
				}
			}
		}
		
		
		// MARK: 4. Process chatrooms
		processChatrooms(partnersChats, privateContext: privateContext)	// This one too large, so i carved it out as a function.
		
		// MARK: 5. Save!
		do {
			try privateContext.save()
		} catch {
			print(error)
		}
	}
}


// MARK: - Processing transactions
extension AdamantChatsProvider {
	private func processChatrooms(_ chats: [String:Set<ChatTransaction>], privateContext: NSManagedObjectContext) {
		for (address, chatTransactions) in chats {
			let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
			request.predicate = NSPredicate(format: "partnerAddress = %@", address)
			request.fetchLimit = 1
			
			// Only one thread should try to search or create chatroom to avoid situations, where two threads will create two chatrooms with one address.
			chatroomsSemaphore.wait()
			let chatroom: Chatroom
			
			let fetchedChatrooms: [Chatroom]
			do {
				fetchedChatrooms = try privateContext.fetch(request)
			} catch {
				print(error)
				return
			}
			
			if let result = fetchedChatrooms.first {
				chatroom = result
			} else {
				var id: NSManagedObjectID! = nil
				
				if Thread.isMainThread { // avoid deadlocks. Whatever.
					let chrm = createChatroom(address: address, context: stack.container.viewContext)
					id = chrm.objectID
				} else {
					DispatchQueue.main.sync {
						let chrm = createChatroom(address: address, context: stack.container.viewContext)
						id = chrm.objectID
					}
				}
				
				if let object = privateContext.object(with: id) as? Chatroom {
					chatroom = object
				} else {
					print("Something wrong here... Skip this chat")
					continue
				}
			}
			
			chatroomsSemaphore.signal()
			
			chatroom.addToTransactions(chatTransactions as NSSet)
			
			if let newest = chatTransactions.sorted(by: { ($0.date! as Date).compare($1.date! as Date) == .orderedDescending }).first {
				if let last = chatroom.lastTransaction {
					if (last.date! as Date).compare(newest.date! as Date) == .orderedAscending {
						chatroom.lastTransaction = newest
						chatroom.updatedAt = newest.date
					}
				} else {
					chatroom.lastTransaction = newest
					chatroom.updatedAt = newest.date
				}
			}
		}
	}
}


// MARK: - Tools
extension AdamantChatsProvider {
	
	/// Parse raw transaction into CoreData chat transaction
	///
	/// - Parameters:
	///   - transaction: Raw transaction
	///   - currentAddress: logged account address
	///   - privateKey: logged account private key
	///   - context: context to insert parsed transaction to
	/// - Returns: New parsed transaction
	private func chatTransaction(from transaction: Transaction, isOutgoing: Bool, publicKey: String, privateKey: String, context: NSManagedObjectContext) -> ChatTransaction? {
		guard let chat = transaction.asset.chat else {
			return nil
		}
		
		let chatTransaction = ChatTransaction(entity: ChatTransaction.entity(), insertInto: context)
		chatTransaction.date = transaction.date as NSDate
		chatTransaction.recipientId = transaction.recipientId
		chatTransaction.senderId = transaction.senderId
		chatTransaction.transactionId = String(transaction.id)
		chatTransaction.type = Int16(chat.type.rawValue)
		chatTransaction.height = Int64(transaction.height)
		chatTransaction.isConfirmed = true
		chatTransaction.isOutgoing = isOutgoing
		
		let decodedMessage = adamantCore.decodeMessage(rawMessage: chat.message, rawNonce: chat.ownMessage, senderPublicKey: publicKey, privateKey: privateKey)
		
		if let decodedMessage = decodedMessage,
			let translatedMessage = contactsService.translated(message: decodedMessage, from: transaction.senderId) {
			chatTransaction.message = translatedMessage
		} else {
			chatTransaction.message = decodedMessage
		}
		
		return chatTransaction
	}
	
	
	/// Confirm transactions
	///
	/// - Parameters:
	///   - transaction: Unconfirmed transaction
	///   - id: New transaction id
	///   - height: New transaction height
	private func confirmTransaction(_ transaction: ChatTransaction, id: UInt, height: Int) {
		if transaction.isConfirmed {
			return
		}
		
		transaction.isConfirmed = true
		transaction.height = Int64(height)
		self.unconfirmedTransactions.removeValue(forKey: id)
		
		if let lastHeight = lastHeight, lastHeight < height {
			self.lastHeight = height
		}
	}
	
	
	/// Create and configure Chatroom
	///
	/// - Parameters:
	///   - address: chatroom with
	///   - context: Context to insert chatroom into
	/// - Returns: Chatroom
	private func createChatroom(address: String, context: NSManagedObjectContext) -> Chatroom {
		let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		chatroom.partnerAddress = address
		chatroom.updatedAt = NSDate()
		
		if let title = contactsService.nameFor(address: address) {
			chatroom.title = title
		}
		
		return chatroom
	}
}
