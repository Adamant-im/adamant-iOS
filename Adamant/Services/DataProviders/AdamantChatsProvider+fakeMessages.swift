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
	func fakeSent(message: AdamantMessage, recipientId: String, date: Date, completion: @escaping (ChatsProviderResult) -> Void) {
		validate(message: message, partnerId: recipientId) { [weak self] result in
			switch result {
			case .success(let loggedAddress, let partner):
				switch message {
				case .text(let text):
					self?.fakeSent(text: text, loggedAddress: loggedAddress, recipient: partner, date: date, markdown: false, completion: completion)
					
				case .markdownText(let text):
					self?.fakeSent(text: text, loggedAddress: loggedAddress, recipient: partner, date: date, markdown: true, completion: completion)
				}
				
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
	
	func fakeReceived(message: AdamantMessage, senderId: String, date: Date, unread: Bool, silent: Bool, completion: @escaping (ChatsProviderResult) -> Void) {
		validate(message: message, partnerId: senderId) { [weak self] result in
			switch result {
			case .success(let loggedAccount, let partner):
				switch message {
				case .text(let text):
					self?.fakeReceived(text: text, loggedAddress: loggedAccount, sender: partner, date: date, unread: unread, silent: silent, markdown: false, completion: completion)
					
				case .markdownText(let text):
					self?.fakeReceived(text: text, loggedAddress: loggedAccount, sender: partner, date: date, unread: unread, silent: silent, markdown: true, completion: completion)
				}
				
			case .failure(let error):
				completion(.failure(error))
			}
		}
	}
    
    func fakeSendFailMessage(_ message: AdamantMessage, recipientId: String, completion: @escaping (ChatsProviderResult) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        guard loggedAccount.balance >= message.fee else {
            completion(.failure(.notEnoughtMoneyToSend))
            return
        }
        
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
        
        let sendingQueue = DispatchQueue(label: "im.adamant.sending.chat.fake", qos: .utility, attributes: [.concurrent])

        sendingQueue.async {
            switch message {
            case .text(let text), .markdownText(let text):
                self.fakeSendFailMessage(text: text, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, completion: completion)
            }
        }
    }
    
    func fakeReSendMessage(_ transaction: MessageTransaction, recipientId: String, completion: @escaping (ChatsProviderResult) -> Void) {
        print("Fake resending")
        
        guard let text = transaction.message else {
            return
        }
        
        let message = AdamantMessage.text(text)
        
        guard let loggedAccount = accountService.account else {
            completion(.failure(.notLogged))
            return
        }
        
        guard loggedAccount.balance >= message.fee else {
            completion(.failure(.notEnoughtMoneyToSend))
            return
        }
        
        // MARK: 0. Prepare
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        // MARK 4. Update transaction
        let request = NSFetchRequest<MessageTransaction>(entityName: MessageTransaction.entityName)
        request.predicate = NSPredicate(format: "transactionId == %@", transaction.messageId)
        request.fetchLimit = 1
        if let transaction = (try? privateContext.fetch(request))?.first {
            transaction.date = Date() as NSDate
            transaction.statusEnum = MessageStatus.pending
            
            // MARK: 5. Save unconfirmed transaction
            do {
                try privateContext.save()
            } catch {
                completion(.failure(.internalError(error)))
                return
            }
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
                print("Fake success recive")
                transaction.statusEnum = MessageStatus.sent
                try? privateContext.save()
                completion(.success)
            })
        }
    }
	
	// MARK: - Logic
	
	private func fakeSent(text: String, loggedAddress: String, recipient: CoreDataAccount, date: Date, markdown: Bool, completion: @escaping (ChatsProviderResult) -> Void) {
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
		transaction.isMarkdown = markdown
		
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
	
	private func fakeReceived(text: String, loggedAddress: String, sender: CoreDataAccount, date: Date, unread: Bool, silent: Bool, markdown: Bool, completion: @escaping (ChatsProviderResult) -> Void) {
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
		transaction.isMarkdown = markdown
		
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
    
    private func fakeSendFailMessage(text: String, senderId: String, recipientId: String, keypair: Keypair, completion: @escaping (ChatsProviderResult) -> Void) {
        // MARK: 0. Prepare
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        
        // MARK: 1. Get recipient account
        let accountsGroup = DispatchGroup()
        accountsGroup.enter()
        var acc: CoreDataAccount? = nil
        accountsProvider.getAccount(byAddress: recipientId) { result in
            defer {
                accountsGroup.leave()
            }
            
            switch result {
            case .notFound, .invalidAddress:
                completion(.failure(.accountNotFound(recipientId)))
                
            case .serverError(let error):
                completion(.failure(.serverError(error)))
                
            case .success(let account):
                acc = account
            }
        }
        
        accountsGroup.wait()
        
        guard let account = acc else {
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
        
        transaction.statusEnum = MessageStatus.pending
        
        chatroom.addToTransactions(transaction)
        
        // MARK: 5. Save unconfirmed transaction
        do {
            try privateContext.save()
        } catch {
            completion(.failure(.internalError(error)))
            return
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1, execute: {
            print("Fake fail recive")
            transaction.statusEnum = MessageStatus.fail
            try? privateContext.save()
            completion(.failure(.internalError(AdamantError(message: "fake"))))
        })
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
