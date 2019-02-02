//
//  AdamantChatsProvider+fakeMessages.swift
//  Adamant
//
//  Created by Anokhov Pavel on 02.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

extension AdamantChatsProvider {
	// MARK: - Public
    func fakeSent(message: AdamantMessage, recipientId: String, date: Date, status: MessageStatus, showsChatroom: Bool, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
		validate(message: message, partnerId: recipientId) { [weak self] result in
			switch result {
			case .success(let loggedAddress, let partner):
				switch message {
				case .text(let text):
                    self?.fakeSent(text: text, loggedAddress: loggedAddress, recipient: partner, date: date, status: status, markdown: false, showsChatroom: showsChatroom, completion: completion)
					
				case .richMessage(let payload):
					self?.fakeSent(text: payload.serialized(), loggedAddress: loggedAddress, recipient: partner, date: date, status: status, markdown: false, showsChatroom: showsChatroom, completion: completion)
					
				case .markdownText(let text):
					self?.fakeSent(text: text, loggedAddress: loggedAddress, recipient: partner, date: date, status: status, markdown: true, showsChatroom: showsChatroom, completion: completion)
				}
				
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func fakeReceived(message: AdamantMessage, senderId: String, date: Date, unread: Bool, silent: Bool, showsChatroom: Bool, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
		validate(message: message, partnerId: senderId) { [weak self] result in
			switch result {
			case .success(let loggedAccount, let partner):
				switch message {
				case .text(let text):
                    self?.fakeReceived(text: text, loggedAddress: loggedAccount, sender: partner, date: date, unread: unread, silent: silent, markdown: false, showsChatroom: showsChatroom, completion: completion)
					
				case .richMessage(let payload):
					self?.fakeReceived(text: payload.serialized(), loggedAddress: loggedAccount, sender: partner, date: date, unread: unread, silent: silent, markdown: false, showsChatroom: showsChatroom, completion: completion)
					
				case .markdownText(let text):
					self?.fakeReceived(text: text, loggedAddress: loggedAccount, sender: partner, date: date, unread: unread, silent: silent, markdown: true, showsChatroom: showsChatroom, completion: completion)
				}
				
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
    
	func fakeUpdate(status: MessageStatus, forTransactionId id: String, completion: @escaping (ChatsProviderResult) -> Void) {
		// MARK: 1. Get transaction
		let request = NSFetchRequest<MessageTransaction>(entityName: MessageTransaction.entityName)
		request.predicate = NSPredicate(format: "transactionId == %@", id)
		request.fetchLimit = 1
		
		guard let transaction = (try? stack.container.viewContext.fetch(request))?.first else {
			completion(.failure(.transactionNotFound(id: id)))
			return
		}
		
		// MARK: 2. Update transaction in private context
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
		
		if let trs = privateContext.object(with: transaction.objectID) as? MessageTransaction {
			trs.date = Date() as NSDate
			trs.status = status.rawValue
		} else {
			completion(.failure(.internalError(AdamantError(message: "CoreData changed"))))
			return
		}
        
        // MARK 3. Save changes
		if privateContext.hasChanges {
			do {
				try privateContext.save()
				completion(.success)
			} catch {
				completion(.failure(.internalError(error)))
			}
		} else {
			completion(.success)
		}
    }
	
	// MARK: - Logic
	
	private func fakeSent(text: String, loggedAddress: String, recipient: CoreDataAccount, date: Date, status: MessageStatus, markdown: Bool, showsChatroom: Bool, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
		// MARK: 0. Prepare
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		// MARK: 1. Create transaction
		let transaction = MessageTransaction(entity: MessageTransaction.entity(), insertInto: privateContext)
		transaction.date = date as NSDate
		transaction.recipientId = recipient.address
		transaction.senderId = loggedAddress
		transaction.type = Int16(ChatType.message.rawValue)
		transaction.isOutgoing = true
		transaction.message = text
		transaction.isUnread = false
		transaction.isMarkdown = markdown
		transaction.status = status.rawValue
        transaction.showsChatroom = showsChatroom
        transaction.partner = privateContext.object(with: recipient.objectID) as? BaseAccount
		
		transaction.transactionId = UUID().uuidString
		transaction.blockId = UUID().uuidString
        transaction.chatMessageId = transaction.transactionId
		
		// MARK: 2. Get Chatroom
		guard let id = recipient.chatroom?.objectID, let chatroom = privateContext.object(with: id) as? Chatroom else {
			return
		}
		
		// MARK: 3. Save it
		do {
			chatroom.addToTransactions(transaction)
			recheckLastTransactionFor(chatroom: chatroom, with: transaction)
			try privateContext.save()
            completion(.success(transaction: transaction))
		} catch {
			completion(.failure(.internalError(error)))
		}
	}
	
	private func fakeReceived(text: String, loggedAddress: String, sender: CoreDataAccount, date: Date, unread: Bool, silent: Bool, markdown: Bool, showsChatroom: Bool, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
		// MARK: 0. Prepare
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		// MARK: 1. Create transaction
		let transaction = MessageTransaction(entity: MessageTransaction.entity(), insertInto: privateContext)
		transaction.date = date as NSDate
		transaction.recipientId = loggedAddress
		transaction.senderId = sender.address
		transaction.type = Int16(ChatType.message.rawValue)
		transaction.isOutgoing = false
		transaction.message = text
		transaction.isUnread = unread
		transaction.silentNotification = silent
		transaction.isMarkdown = markdown
		transaction.status = MessageStatus.delivered.rawValue
        transaction.showsChatroom = showsChatroom
        transaction.partner = privateContext.object(with: sender.objectID) as? BaseAccount
		
		transaction.transactionId = UUID().uuidString
		transaction.blockId = UUID().uuidString
        transaction.chatMessageId = transaction.transactionId
		
		// MARK: 2. Get Chatroom
		guard let id = sender.chatroom?.objectID, let chatroom = privateContext.object(with: id) as? Chatroom else {
			return
		}
		
		if unread {
			chatroom.hasUnreadMessages = true
		}
		
		// MARK: 3. Save it
		do {
			chatroom.addToTransactions(transaction)
			recheckLastTransactionFor(chatroom: chatroom, with: transaction)
			try privateContext.save()
            completion(.success(transaction: transaction))
		} catch {
			completion(.failure(.internalError(error)))
		}
	}
	
	// MARK: - Validate & prepare
	
	private enum ValidateResult {
		case success(loggedAccount: String, partner: CoreDataAccount)
		case failure(ChatsProviderError)
	}
	
	private func validate(message: AdamantMessage, partnerId: String, completion: @escaping (ValidateResult) -> Void) {
		// MARK: 1. Logged account
		guard let loggedAddress = accountService.account?.address else {
			completion(.failure(.notLogged))
			return
		}
		
		// MARK: 2. Validate message
		switch validateMessage(message) {
		case .isValid:
			break
			
		case .empty:
			completion(.failure(.messageNotValid(.empty)))
			return
			
		case .tooLong:
			completion(.failure(.messageNotValid(.tooLong)))
			return
		}
		
		// MARK: 3. Get recipient
		accountsProvider.getAccount(byAddress: partnerId) { result in
			switch result {
			case .success(let account):
				completion(.success(loggedAccount: loggedAddress, partner: account))
				
			case .notFound, .invalidAddress, .notInitiated, .dummy(_):
				completion(.failure(.accountNotFound(partnerId)))
				
			case .networkError(_):
				completion(.failure(.networkError))
				
			case .serverError(let error):
				completion(.failure(.serverError(error)))
			}
		}
	}
	
	
	// MARK: - Tools
	
	private func recheckLastTransactionFor(chatroom: Chatroom, with transaction: ChatTransaction) {
		if let ch = transaction.chatroom, ch != chatroom {
			return
		}
		
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
	}
}
