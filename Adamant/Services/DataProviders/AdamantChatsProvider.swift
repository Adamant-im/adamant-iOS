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
	private let highSemaphore = DispatchSemaphore(value: 1)
	private let stateSemaphore = DispatchSemaphore(value: 1)
	
	// MARK: Lifecycle
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedIn, object: nil, queue: nil) { _ in
			self.update()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: nil) { _ in
			self.reset()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: Tools
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
extension AdamantChatsProvider {
	func reload() {
		reset(notify: false)
		update()
	}
	
	func reset() {
		reset(notify: true)
	}
	
	private func reset(notify: Bool) {
		let prevState = self.state
		setState(.updating, previous: prevState, notify: false) // Block update calls
		lastHeight = nil
		
		let chatrooms = NSFetchRequest<Chatroom>(entityName: Chatroom.entityName)
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.parent = stack.container.viewContext
		
		if let results = try? context.fetch(chatrooms) {
			for obj in results {
				context.delete(obj)
			}
			
			try? context.save()
		}
		
		setState(.empty, previous: prevState, notify: notify)
	}
	
	func update() {
		stateSemaphore.wait()
		// MARK: 1. Check state
		if state == .updating {
			return
		}
		
		// MARK: 2. Prepare
		let prevState = state
		
		guard let address = accountService.account?.address else {
			stateSemaphore.signal()
			setState(.failedToUpdate(ChatsProviderError.notLogged), previous: prevState)
			return
		}
		
		state = .updating
		stateSemaphore.signal()
		
		// MARK: 3. Get transactions
		let processingGroup = DispatchGroup()
		getTransactions(address: address, height: lastHeight, offset: nil, dispatchGroup: processingGroup, parentContext: stack.container.viewContext)
		
		// MARK: 4. Check
		processingGroup.notify(queue: DispatchQueue.global(qos: .utility)) {
			switch self.state {
			case .failedToUpdate(_): // Processing failed
				break
				
			default:
				self.setState(.upToDate, previous: prevState)
			}
		}
	}
}


// MARK: - Sending messages {
extension AdamantChatsProvider {
	func sendMessage(_ message: AdamantMessage, recipientId: String, completion: @escaping (ChatsProviderResult) -> Void) {
		switch validateMessage(message) {
		case .isValid:
			break
			
		case .empty:
			completion(.error(.messageNotValid(.empty)))
			return
			
		case .tooLong:
			completion(.error(.messageNotValid(.tooLong)))
			return
		}
		
		DispatchQueue.global(qos: .utility).async {
			switch message {
			case .text(let text):
				self.sendTextMessage(text: text, recipientId: recipientId, completion: completion)
			}
		}
	}
	
	private func sendTextMessage(text: String, recipientId: String, completion: @escaping (ChatsProviderResult) -> Void) {
		guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
			completion(.error(.notLogged))
			return
		}
		
		// MARK: 0. Prepare
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		
		// MARK: 1. Get recipient key
		let accountsGroup = DispatchGroup()
		accountsGroup.enter()
		var objectIdRaw: NSManagedObjectID? = nil
		accountsProvider.getAccount(byAddress: recipientId) { result in
			defer {
				accountsGroup.leave()
			}
			
			switch result {
			case .notFound:
				completion(.error(.accountNotFound(recipientId)))
				
			case .serverError(let error):
				completion(.error(.serverError(error)))
				
			case .success(let account):
				objectIdRaw = account.objectID
			}
		}
		
		accountsGroup.wait()
		guard let objectId = objectIdRaw,
			let recipientAccount = privateContext.object(with: objectId) as? CoreDataAccount,
			let recipientPublicKey = recipientAccount.publicKey else {
			completion(.error(.accountNotFound(recipientId)))
			return
		}
		
		
		// MARK: 2. Encode message
		guard let encodedMessage = adamantCore.encodeMessage(text, recipientPublicKey: recipientPublicKey, privateKey: keypair.privateKey) else {
			completion(.error(.dependencyError("Failed to encode message")))
			return
		}
		
		
		// MARK: 3. Create chat transaction
		let transaction = ChatTransaction(entity: ChatTransaction.entity(), insertInto: privateContext)
		transaction.date = Date() as NSDate
		transaction.recipientId = recipientId
		transaction.senderId = loggedAccount.address
		transaction.type = Int16(ChatType.message.rawValue)
		transaction.isOutgoing = true
		transaction.message = text
		transaction.transactionId = UUID().uuidString
		
		
		// MARK: 4. Save unconfirmed transaction
		do {
			try privateContext.save()
		} catch {
			completion(.error(.internalError(error)))
			return
		}
		
		
		// MARK: 5. Send
		apiService.sendMessage(senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, message: encodedMessage.message, nonce: encodedMessage.nonce) { (id, error) in
			guard let id = id else {
				if let error = error {
					completion(.error(.serverError(error)))
				} else {
					// TODO:
					fatalError()
				}
				return
			}
			
			self.unconfirmedsSemaphore.wait()
			
			transaction.transactionId = String(id)
			self.unconfirmedTransactions[id] = transaction
			
			do {
				try privateContext.save()
				completion(.success)
			} catch {
				completion(.error(.internalError(error)))
			}
			
			self.unconfirmedsSemaphore.signal()
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
		request.predicate = NSPredicate(format: "partner = %@", account)
		
		if let chatroom = (try? context.fetch(request))?.first {
			return chatroom
		}
		
		let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		
		if chatroom.managedObjectContext == account.managedObjectContext {
			chatroom.partner = account
		} else if let acc = chatroom.managedObjectContext?.object(with: account.objectID) as? CoreDataAccount {
			chatroom.partner = acc
		} else {
			// You are too deep, partner.
			fatalError("Not implemented")
		}
		
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
						partners[address] = account
						semaphore.signal()
					}
				}
			}
			
			keysGroup.wait()
		}
		
		if partners.count != partnerAddresses.count {
			// TODO: Log this strange thing
			print("Failed to get all accounts: Needed keys:\n\(partnerAddresses.map { "\($0)\n" })\nFounded Addresses: \(partners.keys.joined(separator: "\n"))")
		}
		
		
		// MARK: 3. Process Transactions, group them by partner
		var partnersChats = [CoreDataAccount: Set<ChatTransaction>]()
		var height: Int64 = 0
		
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
				if height < chatTransaction.height {
					height = chatTransaction.height
				}
				
				if let partnerId = chatTransaction.isOutgoing ? chatTransaction.recipientId : chatTransaction.senderId,
					let partnerAcc = partners[partnerId] {
					if partnersChats[partnerAcc] == nil {
						partnersChats[partnerAcc] = Set<ChatTransaction>()
					}
					
					partnersChats[partnerAcc]!.insert(chatTransaction)
				}
			}
		}
		
		// MARK: 4. Process chatrooms
		processChatrooms(partnersChats, privateContext: privateContext)	// This one too large, so i carved it out as a function.
		
		// MARK: 5. Save!
		do {
			try privateContext.save()
			
			let h = Int(height)
			highSemaphore.wait()
			if let lastHeight = lastHeight {
				if lastHeight < h {
					self.lastHeight = h
				}
			} else {
				lastHeight = h
			}
			highSemaphore.signal()
		} catch {
			print(error)
		}
	}
}


// MARK: - Processing transactions
extension AdamantChatsProvider {
	private func processChatrooms(_ chats: [CoreDataAccount:Set<ChatTransaction>], privateContext: NSManagedObjectContext) {
		for (account, chatTransactions) in chats {
			// Only one thread should try to search or create chatroom to avoid situations, where two threads will create two chatrooms with one address.
			chatroomsSemaphore.wait()
			
			let chatroom: Chatroom
			if let chrm = account.chatroom {
				if chrm.managedObjectContext == privateContext {
					chatroom = chrm
				} else {
					chatroom = privateContext.object(with: chrm.objectID) as! Chatroom
				}
			} else {
				let viewContextAccount: CoreDataAccount
				if account.managedObjectContext == stack.container.viewContext {
					viewContextAccount = account
				} else if let c = stack.container.viewContext.object(with: account.objectID) as? CoreDataAccount {
					viewContextAccount = c
				} else {
					fatalError("What?")
				}
				
				var id: NSManagedObjectID! = nil
				if Thread.isMainThread { // avoid deadlocks. Whatever.
					let chrm = createChatroom(with: viewContextAccount, context: stack.container.viewContext)
					id = chrm.objectID
				} else {
					DispatchQueue.main.sync {
						let chrm = createChatroom(with: viewContextAccount, context: stack.container.viewContext)
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
			
			// Better do this threadsafet
			chatroom.addToTransactions(chatTransactions as NSSet)
			
			chatroomsSemaphore.signal()
			
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
	
	/// Check if message is valid for sending
	func validateMessage(_ message: AdamantMessage) -> ValidateMessageResult {
		switch message {
		case .text(let text):
			if text.count == 0 {
				return .empty
			}
			
			if Double(text.count) * 1.5 > 20000.0 {
				return .tooLong
			}
			
			return .isValid
		}
	}
	
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
	private func createChatroom(with account: CoreDataAccount, context: NSManagedObjectContext) -> Chatroom {
		let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		chatroom.partner = account
		chatroom.updatedAt = NSDate()
		
		if let address = account.address, let title = contactsService.nameFor(address: address) {
			chatroom.title = title
		}
		
		return chatroom
	}
}
