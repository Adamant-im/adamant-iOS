//
//  ChatsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData


// MARK: - Callbacks

enum ChatsProviderResult {
	case success
	case failure(ChatsProviderError)
}

enum ChatsProviderRetryCancelResult {
	case success
	case invalidTransactionStatus(MessageStatus)
	case failure(ChatsProviderError)
}

enum ChatsProviderError: Error {
	case notLogged
	case messageNotValid(ValidateMessageResult)
	case notEnoughtMoneyToSend
	case networkError
	case serverError(Error)
	case accountNotFound(String)
	case dependencyError(String)
	case transactionNotFound(id: String)
	case internalError(Error)
}

enum ValidateMessageResult {
	case isValid
	case empty
	case tooLong
}


// MARK: - Notifications
extension Notification.Name {
	struct AdamantChatsProvider {
		/// Received new messagess. See AdamantUserInfoKey.ChatProvider
		static let newUnreadMessages = Notification.Name("adamant.chatsProvider.newUnreadMessages")

		static let initialSyncFinished = Notification.Name("adamant.chatsProvider.initialSyncFinished")

		private init() {}
	}
}


// MARK: - Notification UserInfo keys
extension AdamantUserInfoKey {
	struct ChatProvider {
		/// newChatroomAddress: Contains new chatroom partner's address as String
		static let newChatroomAddress = "adamant.chatsProvider.newChatroom.address"
		/// lastMessageHeight: new lastMessageHeight
		static let lastMessageHeight = "adamant.chatsProvider.newMessage.lastHeight"
		
		private init() {}
	}
}


// MARK: - SecuredStore keys
extension StoreKey {
	struct chatProvider {
		static let address = "chatProvider.address"
		static let receivedLastHeight = "chatProvider.receivedLastHeight"
		static let readedLastHeight = "chatProvider.readedLastHeight"
		static let notifiedLastHeight = "chatProvider.notifiedLastHeight"
		static let notifiedMessagesCount = "chatProvider.notifiedCount"
	}
}


// MARK: - Protocol
protocol ChatsProvider: DataProvider {
	// MARK: - Properties
	var receivedLastHeight: Int64? { get }
	var readedLastHeight: Int64? { get }
	var isInitiallySynced: Bool { get }
	
	// MARK: - Getting chats and messages
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>
	func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction>
	
	/// Unread messages controller. Sections by chatroom.
	func getUnreadMessagesController() -> NSFetchedResultsController<ChatTransaction>
	
    // ForceUpdate chats
    func forceUpdate(_ completion: ((ChatsProviderResult) -> Void)?)
	
	// MARK: - Sending messages
	func sendMessage(_ message: AdamantMessage, recipientId: String, completion: @escaping (ChatsProviderResult) -> Void )
	func retrySendMessage(_ message: MessageTransaction, completion: @escaping (ChatsProviderRetryCancelResult) -> Void)
    
    // MARK: - Delete local message
    func cancelMessage(_ message: MessageTransaction, completion: @escaping (ChatsProviderRetryCancelResult) -> Void )
	
	// MARK: - Tools
	func validateMessage(_ message: AdamantMessage) -> ValidateMessageResult
	
	// MARK: - Fake messages
	func fakeSent(message: AdamantMessage, recipientId: String, date: Date, status: MessageStatus, completion: @escaping (ChatsProviderResult) -> Void)
	func fakeReceived(message: AdamantMessage, senderId: String, date: Date, unread: Bool, silent: Bool, completion: @escaping (ChatsProviderResult) -> Void)
    func fakeUpdate(status: MessageStatus, forTransactionId id: String, completion: @escaping (ChatsProviderResult) -> Void)
}
