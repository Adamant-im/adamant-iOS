//
//  CoreDataChatProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

class CoreDataChatProvider {
	// MARK: - Dependencies
	var accountService: AccountService!
	var apiService: ApiService!
	var adamantCore: AdamantCore!
	
	
	// MARK: - CoreData
	let model: NSManagedObjectModel
	let coordinator: NSPersistentStoreCoordinator
	let context: NSManagedObjectContext
	
	var unconfirmedTransactions: [UInt:ChatTransaction] = [:]
	
	// MARK: - Properties
	private(set) var status: ProviderStatus = .disabled
	var autoupdateInterval: TimeInterval = 3.0
	
	var autoupdate: Bool = true {
		didSet {
			if autoupdate {
				start()
			} else {
				stop()
			}
		}
	}
	
	/// Amount of maximum transactions returned by API by default
	private static let apiTransactions = 100
	private var timer: Timer?
	private var publicKeys = [String:String]()
	private var lastTransactionHeight: Int = 0
	
	private let updatingDispatchGroup = DispatchGroup()
	
	// MARK: - Init
	init(managedObjectModel modelUrl: URL) {
		model = NSManagedObjectModel(contentsOf: modelUrl)!
		coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
		
		try! coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
		
		context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.persistentStoreCoordinator = coordinator
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedIn, object: nil, queue: nil) { _ in
			if self.autoupdate {
				self.start()
			} else {
				self.reloadChats()
			}
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: nil) { _ in
			self.stop()
			self.context.reset()
		}
	}
	
	deinit {
		stop()
		terminateTransactionProcessing()
	}
	
	func start() {
		if !autoupdate { autoupdate = true }
		
		timer = Timer(timeInterval: autoupdateInterval, repeats: true, block: { _ in
			let timeout = DispatchTime.now() + DispatchTimeInterval.milliseconds(self.autoupdateInterval > 1 ? Int((self.autoupdateInterval - 1.0) * 1000) : 0)
			if self.updatingDispatchGroup.wait(timeout: timeout) == .success {
				self.updateChats()
			} else {
				
			}
		})
		RunLoop.current.add(timer!, forMode: .commonModes)
		timer!.fire()
	}
	
	func stop() {
		if autoupdate { autoupdate = false }
		
		timer?.invalidate()
		timer = nil
	}
}


// MARK: - ChatProvider
extension CoreDataChatProvider: ChatDataProvider {
	
	/// Reload all messages
	func reloadChats() {
		terminateTransactionProcessing()
		status = .updating
		context.reset()
		
		guard let account = accountService.account else {
			return
		}
		
		DispatchQueue.global(qos: .userInitiated).async {
			let reloadDispatchGroup = DispatchGroup()
			_ = self.getTransactions(account: account.address, height: nil, offset: nil, dispatchGroup: reloadDispatchGroup)
			reloadDispatchGroup.wait()
			self.status = .upToDate
		}
	}
	
	/// Get new messages
	func updateChats() {
		switch status {
		// If not initiated - reload
		case .disabled:
			reloadChats()
			return
			
		// If updating - do nothing
		case .updating:
			return
			
		// Do Update
		case .errorSyncing: break
		case .upToDate: break
		}
		
		guard let account = accountService.account else {
			return
		}
		
		status = .updating
		
		DispatchQueue.global(qos: .userInitiated).async {
			let newMessages = self.getTransactions(account: account.address, height: self.lastTransactionHeight, offset: nil, dispatchGroup: self.updatingDispatchGroup)
			self.updatingDispatchGroup.wait()
			
			if newMessages > 0 {
				NotificationCenter.default.post(name: .adamantChatProviderNewTransactions, object: nil)
			}
			
			self.status = .upToDate
		}
	}
	
	/// Drop everything
	func reset() {
		stop()
		context.reset()
		status = .disabled
	}
	
	func isValidMessage(text: String) -> Bool {
		if text.count == 0 {
			return false
		}
		
		if Double(text.count) * 1.5 > 20000.0 {
			return false
		}
		
		return true
	}
}


// MARK: - Chats
extension CoreDataChatProvider {
	func newChatroom(with address: String) -> Chatroom {
		if let chatroom = getChatroomsController()?.fetchedObjects?.first(where: {$0.id == address}) {
			return chatroom
		}
		
		let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		chatroom.id = address
		chatroom.updatedAt = NSDate()
		return chatroom
	}
	
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>? {
		let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		
		do {
			try controller.performFetch()
			return controller
		} catch {
			print("Error fetching request: \(error)")
			return nil
		}
	}
	
	func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction>? {
		let request: NSFetchRequest<ChatTransaction> = NSFetchRequest(entityName: ChatTransaction.entityName)
		request.predicate = NSPredicate(format: "chatroom = %@", chatroom)
		request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		
		do {
			try controller.performFetch()
			return controller
		} catch {
			print("Error fetching request: \(error)")
			return nil
		}
	}
}


// MARK: - Sending messages
extension CoreDataChatProvider {
	func sendTextMessage(recipientId: String, text: String) {
		guard isValidMessage(text: text), let account = accountService.account, let keypair = accountService.keypair else {
			return
		}
		
		// MARK: 1: Get key
		let recipientPublicKey: String
		if let key = publicKeys[recipientId] {
			recipientPublicKey = key
		} else {
			let group = DispatchGroup()
			
			// Enter 1
			group.enter()
			var key: String?
			var error: AdamantError?
			DispatchQueue.global(qos: .userInitiated).async {
				self.apiService.getPublicKey(byAddress: recipientId, completionHandler: { (publicKey, err) in
					key = publicKey
					error = err
					
					// Exit 1
					group.leave()
				})
			}
			
			group.wait()
			
			if let key = key {
				recipientPublicKey = key
				publicKeys[recipientId] = key
			} else {
				// TODO: Display error
				let error = error?.message ?? "Unknown error"
				print("Failed to send message: \(error)")
				return
			}
		}
		
		// MARK: 2: Cretae object
		let transaction = ChatTransaction(entity: ChatTransaction.entity(), insertInto: context)
		transaction.date = Date() as NSDate
		transaction.recipientId = recipientId
		transaction.senderId = account.address
		transaction.type = Int16(ChatType.message.rawValue)
		transaction.isOutgoing = true
		transaction.message = text
		transaction.transactionId = UUID().uuidString // TODO:
		
		let chatroom: Chatroom
		if let ch = getChatroomsController()?.fetchedObjects?.first(where: { $0.id == recipientId }) {
			chatroom = ch
		} else {
			chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		}
		
		chatroom.addToTransactions(transaction)
		chatroom.lastTransaction = transaction
		chatroom.updatedAt = transaction.date
		
		// MARK: 2.5: Encode message
		guard let encodedMessage = adamantCore.encodeMessage(text, recipientPublicKey: recipientPublicKey, privateKey: keypair.privateKey) else {
			// TODO: Show error
			fatalError()
		}
		
		// MARK: 3: Send
		apiService.sendMessage(senderId: account.address, recipientId: recipientId, keypair: keypair, message: encodedMessage.message, nonce: encodedMessage.nonce) { (id, error) in
			guard let id = id else {
				// TODO: Show error, mark message as failed instead of deleting it
				self.context.delete(transaction)
				return
			}
			
			transaction.transactionId = String(id)
			// TODO: Threadsafe
			self.unconfirmedTransactions[id] = transaction
			
			// MARK: 4: Verify manually, if autoupdate is off
			if !self.autoupdate {
				self.apiService.getTransaction(id: id, completionHandler: { (t, error) in
					guard let t = t else {
						// TODO: Show error, mark message as failed instead of deleting it
						self.context.delete(transaction)
						return
					}
					
					self.confirmTransaction(transaction, id: id, height: t.height)
				})
			}
		}
	}
}


// MARK: - Processing Data
extension CoreDataChatProvider {
	
	/// Get new transactions
	///
	/// - Parameters:
	///   - account: for account
	///   - height: last message height
	///   - offset: offset, if greater than 100
	/// - Returns: ammount of new messages was added
	private func getTransactions(account: String, height: Int?, offset: Int?, dispatchGroup: DispatchGroup? = nil) -> Int {
		var newMessages = 0
		
		// Enter 1
		dispatchGroup?.enter()
		
		apiService.getChatTransactions(account: account, height: height, offset: offset) { (transactions, error) in
			guard let transactions = transactions else {
				return
			}
			
			// Enter 2
			dispatchGroup?.enter()
			DispatchQueue.global(qos: .userInitiated).async {
				let new = self.loadChatTransactions(transactions, currentAccount: account)
				// Leave 2
				dispatchGroup?.leave()
				// TODO: Threadsafe
				newMessages += new
			}
			
			if transactions.count == CoreDataChatProvider.apiTransactions {
				let newOffset: Int
				if let offset = offset {
					newOffset = offset + CoreDataChatProvider.apiTransactions
				} else {
					newOffset = CoreDataChatProvider.apiTransactions
				}
				
				// TODO: Threadsafe
				newMessages += self.getTransactions(account: account, height: height, offset: newOffset)
			}
			
			// Leave 1
			dispatchGroup?.leave()
		}
		
		return newMessages
	}
	
	
	/// Load raw blockchain chat transactions, parse them, and add to CoreData
	///
	/// - Parameters:
	///   - trs: transactions
	///   - account: current account
	/// - Returns: new transactions added
	private func loadChatTransactions(_ trs: [Transaction], currentAccount account: String) -> Int {
		guard let privateKey = accountService.keypair?.privateKey else {
			return 0
		}
		
		var chatrooms = [String: Set<ChatTransaction>]()
		var newTransactions = 0
		
		// MARK: 1: Gather publicKeys
		var keysNeeded = [String]()
		
		for transaction in trs {
			let isOutgoingMessage = transaction.senderId == account
			let otherAcc = isOutgoingMessage ? transaction.recipientId : transaction.senderId
			
			if !keysNeeded.contains(otherAcc) && publicKeys[otherAcc] == nil {
				keysNeeded.append(otherAcc)
			}
		}
		
		if keysNeeded.count > 0 {
			var newKeys = [String:String]()
			let group = DispatchGroup()
			
			for address in keysNeeded {
				group.enter()
				DispatchQueue.global(qos: .userInitiated).async {
					self.apiService.getPublicKey(byAddress: address, completionHandler: { (publicKey, error) in
						if let key = publicKey {
							newKeys[address] = key
						} else {
							// TODO: Notify about error
							var message = "Can't get public key for account: \(address)."
							if let error = error {
								message += "Error: \(error)"
							}
							print(message)
						}
						group.leave()
					})
				}
			}
			
			group.wait()
			
			// TODO: Make this threadsafe.
			for (address, key) in newKeys {
				publicKeys[address] = key
			}
		}
		
		// MARK: 2: Process transactions
		for transaction in trs {
			
			// Confirm and skip unconfirmed transactions
			// TODO: Make this threadsafe
			if let unconfirmed = unconfirmedTransactions[transaction.id] {
				confirmTransaction(unconfirmed, id: transaction.id, height: transaction.height)
				continue
			}
			
			if let chatTransaction = chatTransaction(from: transaction, currentAddress: account, privateKey: privateKey) {
				newTransactions += 1
				
				// TODO: Make this threadsafe
				if lastTransactionHeight < transaction.height {
					lastTransactionHeight = transaction.height
				}
				
				let partner = chatTransaction.isOutgoing ? transaction.recipientId : transaction.senderId
				
				if chatrooms[partner] == nil {
					chatrooms[partner] = Set<ChatTransaction>()
				}
				
				chatrooms[partner]!.insert(chatTransaction)
			}
		}
		
		// MARK: 3: Process chatrooms
		for (chatId, chatTransactions) in chatrooms {
			let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
			request.predicate = NSPredicate(format: "%K = %@", "id", chatId)
			
			do {
				let result = try context.fetch(request)
				let chatroom: Chatroom
				if let ch = result.first {
					chatroom = ch
				} else {
					chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
					chatroom.id = chatId
				}
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
			} catch {
				print(error)
				continue
			}
		}
		
		return newTransactions
	}
	
	
	/// Parse raw transaction into ChatTransaction
	private func chatTransaction(from transaction: Transaction, currentAddress: String, privateKey: String) -> ChatTransaction? {
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
		
		chatTransaction.isOutgoing = transaction.senderId == currentAddress
		let publicKey = chatTransaction.isOutgoing ? (publicKeys[transaction.recipientId] ?? "") : transaction.senderPublicKey
		
		let decodedMessage = adamantCore.decodeMessage(rawMessage: chat.message, rawNonce: chat.ownMessage, senderPublicKey: publicKey, privateKey: privateKey)
		chatTransaction.message = decodedMessage
		
		return chatTransaction
	}
	
	private func confirmTransaction(_ transaction: ChatTransaction, id: UInt, height: Int) {
		if transaction.isConfirmed {
			return
		}
		
		transaction.isConfirmed = true
		self.unconfirmedTransactions.removeValue(forKey: id)
		
		if self.lastTransactionHeight < transaction.height {
			self.lastTransactionHeight = Int(transaction.height)
		}
		
		transaction.height = Int64(height)
	}
	
	
	private func terminateTransactionProcessing() {
		// TODO: Not implemented
	}
}
