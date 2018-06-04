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
	func fakeSentMessage(_ message: AdamantMessage, recipientId: String, date: Date, completion: @escaping (ChatsProviderResult) -> Void) {
		validate(message: message, partnerId: recipientId) { [weak self] result in
			switch result {
			case .success(let loggedAddress, let partner):
				switch message {
				case .text(let text):
					self?.fakeSentTextMessage(text: text, loggedAddress: loggedAddress, recipient: partner, date: date, completion: completion)
				}
				
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func fakeReceivedMessage(_ message: AdamantMessage, senderId: String, date: Date, unread: Bool, silent: Bool, completion: @escaping (ChatsProviderResult) -> Void) {
		validate(message: message, partnerId: senderId) { [weak self] result in
			switch result {
			case .success(let loggedAccount, let partner):
				switch message {
				case .text(let text):
					self?.fakeReceivedTextMessage(text: text, loggedAddress: loggedAccount, sender: partner, date: date, unread: unread, silent: silent, completion: completion)
				}
				
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	
	// MARK: - Logic
	
	func fakeSentTextMessage(text: String, loggedAddress: String, recipient: CoreDataAccount, date: Date, completion: @escaping (ChatsProviderResult) -> Void) {
		// MARK: 0. Prepare
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		// MARK: 1. Create transaction
		let transaction = MessageTransaction(entity: MessageTransaction.entity(), insertInto: privateContext)
		transaction.date = date as NSDate
		transaction.recipientId = recipient.address
		transaction.senderId = loggedAddress
		transaction.type = ChatType.message.rawValue
		transaction.isOutgoing = true
		transaction.message = text
		transaction.isUnread = false
		
		transaction.transactionId = UUID().uuidString
		transaction.blockId = UUID().uuidString
		
		// MARK: 2. Get Chatroom
		guard let id = recipient.chatroom?.objectID, let chatroom = privateContext.object(with: id) as? Chatroom else {
			return
		}
		
		// MARK: 3. Save it
		do {
			chatroom.addToTransactions(transaction)
			recheckLastTransactionFor(chatroom: chatroom, with: transaction)
			try privateContext.save()
			completion(.success)
		} catch {
			completion(.failure(.internalError(error)))
		}
	}
	
	private func fakeReceivedTextMessage(text: String, loggedAddress: String, sender: CoreDataAccount, date: Date, unread: Bool, silent: Bool, completion: @escaping (ChatsProviderResult) -> Void) {
		// MARK: 0. Prepare
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		// MARK: 1. Create transaction
		let transaction = MessageTransaction(entity: MessageTransaction.entity(), insertInto: privateContext)
		transaction.date = date as NSDate
		transaction.recipientId = loggedAddress
		transaction.senderId = sender.address
		transaction.type = ChatType.message.rawValue
		transaction.isOutgoing = false
		transaction.message = text
		transaction.isUnread = unread
		transaction.silentNotification = silent
		
		transaction.transactionId = UUID().uuidString
		transaction.blockId = UUID().uuidString
		
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
			completion(.success)
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
				
			case .notFound, .invalidAddress:
				completion(.failure(.accountNotFound(partnerId)))
				
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
