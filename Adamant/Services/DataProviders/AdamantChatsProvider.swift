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
	var accountsProvider: AccountsProvider!
	var securedStore: SecuredStore!
	
	// MARK: Properties
	private(set) var state: State = .empty
	private(set) var receivedLastHeight: Int64?
	private(set) var readedLastHeight: Int64?
	private let apiTransactions = 100
	private var unconfirmedTransactions: [UInt64:MessageTransaction] = [:]
	
	private let processingQueue = DispatchQueue(label: "im.adamant.processing.chat", qos: .utility, attributes: [.concurrent])
	private let sendingQueue = DispatchQueue(label: "im.adamant.sending.chat", qos: .utility, attributes: [.concurrent])
	private let unconfirmedsSemaphore = DispatchSemaphore(value: 1)
	private let highSemaphore = DispatchSemaphore(value: 1)
	private let stateSemaphore = DispatchSemaphore(value: 1)
	
	// MARK: Lifecycle
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedIn, object: nil, queue: nil) { [weak self] notification in
			guard let store = self?.securedStore else {
				return
			}
			
			guard let loggedAddress = notification.userInfo?[AdamantUserInfoKey.AccountService.loggedAccountAddress] as? String else {
				store.remove(StoreKey.chatProvider.address)
				store.remove(StoreKey.chatProvider.receivedLastHeight)
				store.remove(StoreKey.chatProvider.readedLastHeight)
				return
			}
			
			if let savedAddress = self?.securedStore.get(StoreKey.chatProvider.address), savedAddress == loggedAddress {
				if let raw = store.get(StoreKey.chatProvider.readedLastHeight), let h = Int64(raw) {
					self?.readedLastHeight = h
				}
			} else {
				store.remove(StoreKey.chatProvider.receivedLastHeight)
				store.remove(StoreKey.chatProvider.readedLastHeight)
				store.set(loggedAddress, for: StoreKey.chatProvider.address)
			}
			
			self?.update()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.receivedLastHeight = nil
			self?.readedLastHeight = nil
			if let prevState = self?.state {
				self?.setState(.empty, previous: prevState, notify: true)
			}
			
			if let store = self?.securedStore {
				store.remove(StoreKey.chatProvider.address)
				store.remove(StoreKey.chatProvider.receivedLastHeight)
				store.remove(StoreKey.chatProvider.readedLastHeight)
			}
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
		
		receivedLastHeight = nil
		readedLastHeight = nil
		securedStore.remove(StoreKey.chatProvider.receivedLastHeight)
		securedStore.remove(StoreKey.chatProvider.readedLastHeight)
		
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
		if state == .updating {
			return
		}
		
		stateSemaphore.wait()
		// MARK: 1. Check state
		if state == .updating {
			stateSemaphore.signal()
			return
		}
		
		// MARK: 2. Prepare
		let prevState = state
		
		guard let address = accountService.account?.address, let privateKey = accountService.keypair?.privateKey else {
			stateSemaphore.signal()
			setState(.failedToUpdate(ChatsProviderError.notLogged), previous: prevState)
			return
		}
		
		state = .updating
		stateSemaphore.signal()
		
		// MARK: 3. Get transactions
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = self.stack.container.viewContext
		let processingGroup = DispatchGroup()
		let cms = DispatchSemaphore(value: 1)
		let prevHeight = receivedLastHeight
		
		getTransactions(senderId: address, privateKey: privateKey, height: receivedLastHeight, offset: nil, dispatchGroup: processingGroup, context: privateContext, contextMutatingSemaphore: cms)
		
		// MARK: 4. Check
		processingGroup.notify(queue: DispatchQueue.global(qos: .utility)) { [weak self] in
			guard let state = self?.state else {
				return
			}
			
			switch state {
			case .failedToUpdate(_): // Processing failed
				break
				
			default:
				self?.setState(.upToDate, previous: prevState)
				
				if prevHeight != self?.receivedLastHeight, let h = self?.receivedLastHeight {
					NotificationCenter.default.post(name: Notification.Name.adamantChatsProviderNewUnreadMessages,
													object: self,
													userInfo: [AdamantUserInfoKey.ChatProvider.lastMessageHeight:h])
				}
				
				if let h = self?.receivedLastHeight {
					self?.readedLastHeight = h
				} else {
					self?.readedLastHeight = 0
				}
				
				if let store = self?.securedStore {
					if let h = self?.receivedLastHeight {
						store.set(String(h), for: StoreKey.chatProvider.receivedLastHeight)
					}
					
					if let h = self?.readedLastHeight, h > 0 {
						store.set(String(h), for: StoreKey.chatProvider.readedLastHeight)
					}
				}
			}
		}
	}
}


// MARK: - Sending messages {
extension AdamantChatsProvider {
	func sendMessage(_ message: AdamantMessage, recipientId: String, completion: @escaping (ChatsProviderResult) -> Void) {
		guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
			completion(.error(.notLogged))
			return
		}
		
		guard loggedAccount.balance >= message.fee else {
			completion(.error(.notEnoughtMoneyToSend))
			return
		}
		
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
		
		sendingQueue.async {
			switch message {
			case .text(let text):
				self.sendTextMessage(text: text, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, completion: completion)
			}
		}
	}
	
	private func sendTextMessage(text: String, senderId: String, recipientId: String, keypair: Keypair, completion: @escaping (ChatsProviderResult) -> Void) {
		// MARK: 0. Prepare
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		
		// MARK: 1. Get recipient account
		let accountsGroup = DispatchGroup()
		accountsGroup.enter()
		var accountViewContext: CoreDataAccount? = nil
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
				accountViewContext = account
			}
		}
		
		accountsGroup.wait()
		
		guard let account = accountViewContext, let recipientPublicKey = account.publicKey else {
			completion(.error(.accountNotFound(recipientId)))
			return
		}
		
		
		// MARK: 2. Encode message
		guard let encodedMessage = adamantCore.encodeMessage(text, recipientPublicKey: recipientPublicKey, privateKey: keypair.privateKey) else {
			completion(.error(.dependencyError("Failed to encode message")))
			return
		}
		
		
		// MARK 3. Get Chatroom
		let chatroom = privateContext.object(with: account.chatroom!.objectID) as! Chatroom
		
		
		// MARK: 4. Create chat transaction
		let transaction = MessageTransaction(entity: MessageTransaction.entity(), insertInto: privateContext)
		transaction.date = Date() as NSDate
		transaction.recipientId = recipientId
		transaction.senderId = senderId
		transaction.type = ChatType.message.rawValue
		transaction.isOutgoing = true
		transaction.message = text
		
		transaction.transactionId = UUID().uuidString
		transaction.blockId = UUID().uuidString
		
		chatroom.addToTransactions(transaction)
		
		
		// MARK: 5. Save unconfirmed transaction
		do {
			try privateContext.save()
		} catch {
			completion(.error(.internalError(error)))
			return
		}
		
		// MARK: 6. Send
		apiService.sendMessage(senderId: senderId, recipientId: recipientId, keypair: keypair, message: encodedMessage.message, nonce: encodedMessage.nonce) { result in
			switch result {
			case .success(let id):
				// Update ID with recieved, add to unconfirmed transactions.
				transaction.transactionId = String(id)
				
				if let lastTransaction = chatroom.lastTransaction {
					if let dateA = lastTransaction.date as Date?, let dateB = transaction.date as Date?,
						dateA.compare(dateB) == ComparisonResult.orderedAscending {
						chatroom.lastTransaction = transaction
						chatroom.updatedAt = transaction.date
					}
				} else {
					chatroom.lastTransaction = transaction
					chatroom.updatedAt = transaction.date
				}
				
				// If we will save transaction from privateContext, we will hold strong reference to whole context, and we won't ever save it.
				self.unconfirmedsSemaphore.wait()
				DispatchQueue.main.sync {
					self.unconfirmedTransactions[id] = self.stack.container.viewContext.object(with: transaction.objectID) as? MessageTransaction
				}
				self.unconfirmedsSemaphore.signal()
				
				do {
					try privateContext.save()
					completion(.success)
				} catch {
					completion(.error(.internalError(error)))
				}
				
				
			case .failure(let error):
				privateContext.delete(transaction)
				try? privateContext.save()
				
				let serviceError: ChatsProviderError
				switch error {
				case .networkError(_):
					serviceError = .networkError
					
				case .accountNotFound:
					serviceError = .accountNotFound(recipientId)
					
				case .notLogged:
					serviceError = .notLogged
					
				case .serverError(let e):
					serviceError = .serverError(AdamantError(message: e))
					
				case .internalError(let message, let e):
					serviceError = ChatsProviderError.internalError(AdamantError(message: message, error: e))
				}
				
				completion(.error(serviceError))
			}
		}
	}
}


// MARK: - Getting messages
extension AdamantChatsProvider {
	func getChatroomsController() -> NSFetchedResultsController<Chatroom> {
		let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false),
								   NSSortDescriptor(key: "height", ascending: false)]
		request.predicate = NSPredicate(format: "partner!=nil")
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return controller
	}
	
	func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction> {
		guard let context = chatroom.managedObjectContext else {
			fatalError()
		}
		
		let request: NSFetchRequest<ChatTransaction> = NSFetchRequest(entityName: "ChatTransaction")
		request.predicate = NSPredicate(format: "chatroom = %@", chatroom)
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true),
								   NSSortDescriptor(key: "height", ascending: true)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		
		return controller
	}
	
	func getUnreadMessagesController() -> NSFetchedResultsController<ChatTransaction> {
		let request = NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
		request.predicate = NSPredicate(format: "isUnread == true")
		request.sortDescriptors = [NSSortDescriptor.init(key: "date", ascending: false),
								   NSSortDescriptor(key: "height", ascending: false)]
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: "chatroom.partner.address", cacheName: nil)
		
		return controller
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
	private func getTransactions(senderId: String,
								 privateKey: String,
								 height: Int64?,
								 offset: Int?,
								 dispatchGroup: DispatchGroup,
								 context: NSManagedObjectContext,
								 contextMutatingSemaphore cms: DispatchSemaphore) {
		// Enter 1
		dispatchGroup.enter()
		
		// MARK: 1. Get new transactions
		apiService.getMessageTransactions(address: senderId, height: height, offset: offset) { result in
			defer {
				// Leave 1
				dispatchGroup.leave()
			}
			
			switch result {
			case .success(let transactions):
				if transactions.count == 0 {
					return
				}
				
				// MARK: 2. Process transactions in background
				// Enter 2
				dispatchGroup.enter()
				self.processingQueue.async {
					defer {
						// Leave 2
						dispatchGroup.leave()
					}
					
					self.process(messageTransactions: transactions,
								 senderId: senderId,
								 privateKey: privateKey,
								 context: context,
								 contextMutatingSemaphore: cms)
				}
				
				// MARK: 4. Get more transactions
				if transactions.count == self.apiTransactions {
					let newOffset: Int
					if let offset = offset {
						newOffset = offset + self.apiTransactions
					} else {
						newOffset = self.apiTransactions
					}
					
					self.getTransactions(senderId: senderId, privateKey: privateKey, height: height, offset: newOffset, dispatchGroup: dispatchGroup, context: context, contextMutatingSemaphore: cms)
				}
				
			case .failure(let error):
				self.setState(.failedToUpdate(error), previous: .updating)
			}
		}
	}
	
	
	/// - Returns: New unread messagess ids
	private func process(messageTransactions: [Transaction],
						 senderId: String,
						 privateKey: String,
						 context: NSManagedObjectContext,
						 contextMutatingSemaphore: DispatchSemaphore) {
		struct DirectionedTransaction {
			let transaction: Transaction
			let isOut: Bool
		}
		
		// MARK: 1. Gather partner keys
		let mapped = messageTransactions.map({ DirectionedTransaction(transaction: $0, isOut: $0.senderId == senderId) })
		let grouppedTransactions = Dictionary(grouping: mapped, by: { $0.isOut ? $0.transaction.recipientId : $0.transaction.senderId })
		
		
		// MARK: 2. Gather Accounts
		var partners: [CoreDataAccount:[DirectionedTransaction]] = [:]
		
		let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
		request.fetchLimit = grouppedTransactions.count
		let predicates = grouppedTransactions.keys.map { NSPredicate(format: "address = %@", $0) }
		request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
		
		if let results = try? context.fetch(request) {
			for account in results {
				if let address = account.address, let transactions = grouppedTransactions[address] {
					partners[account] = transactions
				}
			}
		}
		
		// MARK: 2.5 Get accounts, that we did not found.
		if partners.count != grouppedTransactions.keys.count {
			let foundedKeys = partners.keys.compactMap {$0.address}
			let notFound = Set<String>(grouppedTransactions.keys).subtracting(foundedKeys)
			var ids = [NSManagedObjectID]()
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
						ids.append(account.objectID)
						semaphore.signal()
					}
				}
			}
			
			keysGroup.wait()
			
			// Get in our context
			for id in ids {
				if let account = context.object(with: id) as? CoreDataAccount, let address = account.address, let transactions = grouppedTransactions[address] {
					partners[account] = transactions
				}
			}
		}
		
		if partners.count != grouppedTransactions.keys.count {
			// TODO: Log this strange thing
			print("Failed to get all accounts: Needed keys:\n\(grouppedTransactions.keys.joined(separator: "\n"))\nFounded Addresses: \(partners.keys.compactMap { $0.address }.joined(separator: "\n"))")
		}
		
		
		// MARK: 3. Process Chatrooms and Transactions
		var height: Int64 = 0
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = context
		var newMessageTransactions = [MessageTransaction]()
		
		for (account, transactions) in partners {
			// We can't save whole context while we are mass creating MessageTransactions.
			let privateChatroom = privateContext.object(with: account.chatroom!.objectID) as! Chatroom
			
			// MARK: Transactions
			var messages = Set<MessageTransaction>()
			
			for trs in transactions {
				unconfirmedsSemaphore.wait()
				if unconfirmedTransactions.count > 0, let unconfirmed = unconfirmedTransactions[trs.transaction.id] {
					confirmTransaction(unconfirmed, id: trs.transaction.id, height: Int64(trs.transaction.height), blockId: trs.transaction.blockId, confirmations: trs.transaction.confirmations)
					let h = Int64(trs.transaction.height)
					if height < h {
						height = h
					}
					
					unconfirmedsSemaphore.signal()
					continue
				} else {
					unconfirmedsSemaphore.signal()
				}
				
				let publicKey: String
				if trs.isOut {
					publicKey = account.publicKey ?? ""
				} else {
					publicKey = trs.transaction.senderPublicKey
				}
				
				if let messageTransaction = messageTransaction(from: trs.transaction, isOutgoing: trs.isOut, publicKey: publicKey, privateKey: privateKey, context: privateContext) {
					if height < messageTransaction.height {
						height = messageTransaction.height
					}
					
					if !trs.isOut {
						newMessageTransactions.append(messageTransaction)
						
						// Preset messages
						if let preset = account.knownMessages,
							let message = messageTransaction.message,
							let translatedMessage = preset.first(where: {message.range(of: $0.key) != nil}) {
							messageTransaction.message = translatedMessage.value
						}
					}
					
					messages.insert(messageTransaction)
				}
			}
			
			privateChatroom.addToTransactions(messages as NSSet)
		}
		
		
		// MARK: 4. Unread messagess
		if let readedLastHeight = readedLastHeight {
			let msgs = Dictionary(grouping: newMessageTransactions.filter({$0.height > readedLastHeight}), by: ({ (t: MessageTransaction) -> Chatroom in t.chatroom!}))
			for (chatroom, trs) in msgs {
				chatroom.hasUnreadMessages = true
				trs.forEach({$0.isUnread = true})
			}
		}
		
		
		// MARK: 5. Dump new transactions
		if privateContext.hasChanges {
			do {
				defer {
					contextMutatingSemaphore.signal()
				}
				
				contextMutatingSemaphore.wait()
				
				try privateContext.save()
			} catch {
				print(error)
			}
		}
		
		
		// MARK: 6. Save to main!
		if context.hasChanges {
			do {
				defer {
					contextMutatingSemaphore.signal()
				}
				
				contextMutatingSemaphore.wait()
				
				try context.save()
				
				// MARK: 6. Update lastTransaction
				let viewContextChatrooms = Set<Chatroom>(partners.keys.compactMap { $0.chatroom }).compactMap { self.stack.container.viewContext.object(with: $0.objectID) as? Chatroom }
				
				DispatchQueue.main.async {
					viewContextChatrooms.forEach { $0.updateLastTransaction() }
				}
			} catch {
				print(error)
			}
		}
		
		
		// MARK 7. Last message height
		highSemaphore.wait()
		if let lastHeight = receivedLastHeight {
			if lastHeight < height {
				self.receivedLastHeight = height
			}
		} else {
			receivedLastHeight = height
		}
		
		highSemaphore.signal()
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
	private func messageTransaction(from transaction: Transaction, isOutgoing: Bool, publicKey: String, privateKey: String, context: NSManagedObjectContext) -> MessageTransaction? {
		guard let chat = transaction.asset.chat else {
			return nil
		}
		
		let messageTransaction = MessageTransaction(entity: MessageTransaction.entity(), insertInto: context)
		messageTransaction.date = transaction.date as NSDate
		messageTransaction.recipientId = transaction.recipientId
		messageTransaction.senderId = transaction.senderId
		messageTransaction.transactionId = String(transaction.id)
		messageTransaction.type = Int16(chat.type.rawValue)
		messageTransaction.height = Int64(transaction.height)
		messageTransaction.isConfirmed = true
		messageTransaction.isOutgoing = isOutgoing
		messageTransaction.blockId = transaction.blockId
		messageTransaction.confirmations = transaction.confirmations
		
		if let decodedMessage = adamantCore.decodeMessage(rawMessage: chat.message, rawNonce: chat.ownMessage, senderPublicKey: publicKey, privateKey: privateKey) {
			messageTransaction.message = decodedMessage
		}
		
		return messageTransaction
	}
	
	
	/// Confirm transactions
	///
	/// - Parameters:
	///   - transaction: Unconfirmed transaction
	///   - id: New transaction id	///   - height: New transaction height
	private func confirmTransaction(_ transaction: MessageTransaction, id: UInt64, height: Int64, blockId: String, confirmations: Int64) {
		if transaction.isConfirmed {
			return
		}
		
		transaction.isConfirmed = true
		transaction.height = height
		transaction.blockId = blockId
		transaction.confirmations = confirmations
		self.unconfirmedTransactions.removeValue(forKey: id)
		
		if let lastHeight = receivedLastHeight, lastHeight < height {
			self.receivedLastHeight = height
		}
	}
}
