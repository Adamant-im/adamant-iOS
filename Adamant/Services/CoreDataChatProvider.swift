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
	
	// MARK: - CoreData
	let model: NSManagedObjectModel
	let coordinator: NSPersistentStoreCoordinator
	let context: NSManagedObjectContext
	
	lazy var chatTransactionEntity = {
		return NSEntityDescription.entity(forEntityName: ChatTransaction.entityName, in: context)!
	}()
	
	lazy var chatroomEntity = {
		return NSEntityDescription.entity(forEntityName: Chatroom.entityName, in: context)!
	}()
	
	// MARK: - Init
	init(managedObjectModel modelUrl: URL) {
		model = NSManagedObjectModel(contentsOf: modelUrl)!
		coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
		
		try! coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
		
		context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.persistentStoreCoordinator = coordinator
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedIn, object: nil, queue: nil) { _ in self.reloadChats() }
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: nil) { _ in self.context.reset() }
	}
}


// MARK: - ChatProvider
extension CoreDataChatProvider: ChatDataProvider {
	func reloadChats() {
		context.reset()
		
		guard let account = accountService.loggedAccount else {
			return
		}
		
		getTransactions(account: account.address, height: nil, offset: nil)
	}
	
	func reset() {
		context.reset()
	}
	
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>? {
		let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
		request.sortDescriptors = [NSSortDescriptor(key: "lastTransaction.date", ascending: false)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		
		do {
			try controller.performFetch()
			return controller
		} catch {
			return nil
		}
	}
}


// MARK: - Processing Data
extension CoreDataChatProvider {
	private func getTransactions(account: String, height: Int?, offset: Int?) {
		apiService.getChatTransactions(account: account, height: height, offset: offset) { (transactions, error) in
			guard let transactions = transactions else {
				return
			}
			
			self.loadChatTransactions(transactions, currentAccount: account)
			
			if transactions.count == 100 {
				let newOffset = offset != nil ? offset : 0 + 100
				
				self.getTransactions(account: account, height: height, offset: newOffset)
			} else {
				// TODO: Notification
			}
		}
	}
	
	private func loadChatTransactions(_ trs: [Transaction], currentAccount acc: String) {
		var chatrooms = [String: Set<ChatTransaction>]()
		
		for transaction in trs {
			guard let chat = transaction.asset.chat else {
				continue
			}
			
			let t = ChatTransaction(entity: chatTransactionEntity, insertInto: context)
			t.date = transaction.date as NSDate
			t.receiver = transaction.recipientId
			t.sender = transaction.senderId
			t.type = Int16(chat.type.rawValue)
			
			// TODO: Decode message
			t.message = chat.message
			t.ownMessage = chat.ownMessage
			
			let chatWith = transaction.recipientId == acc ? transaction.senderId : transaction.recipientId
			if var chatroom = chatrooms[chatWith] {
				chatroom.insert(t)
			} else {
				chatrooms[chatWith] = [t]
			}
		}
		
		for (chatId, chatTransactions) in chatrooms {
			let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
			request.predicate = NSPredicate(format: "%K = %@", "id", chatId)
			
			do {
				let result = try context.fetch(request)
				let chatroom: Chatroom
				if let ch = result.first {
					chatroom = ch
				} else {
					chatroom = Chatroom(entity: chatroomEntity, insertInto: context)
					chatroom.id = chatId
				}
				chatroom.addToTransactions(chatTransactions as NSSet)
				
				let newest = chatTransactions.sorted{ ($0.date! as Date).compare($1.date! as Date) == .orderedDescending }.first
				
				if let last = chatroom.lastTransaction {
					if let newest = newest,
						(last.date! as Date).compare(newest.date! as Date) == .orderedAscending {
						chatroom.lastTransaction = newest
					}
				} else {
					chatroom.lastTransaction = newest
				}
			} catch {
				print(error)
				continue
			}
		}
	}
}
