//
//  ChatsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

enum ChatsProviderResult {
	case success
	case error(ChatsProviderError)
}

enum ChatsProviderError: Error {
	case notLogged
	case messageNotValid(ValidateMessageResult)
	case serverError(Error)
	case accountNotFound(String)
	case dependencyError(String)
	case internalError(Error)
}

enum ValidateMessageResult {
	case isValid
	case empty
	case tooLong
}

/// Available message types
enum AdamantMessage {
	case text(String)
}

extension Notification.Name {
	static let adamantChatsProviderNewChatroom = Notification.Name("adamantChatsProviderNewChatroom")
	static let adamantChatsProviderNewTransactions = Notification.Name("adamantChatsProviderNewTransactions")
}

protocol ChatsProvider: DataProvider {
	// MARK: - Getting chats and messages
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>?
	func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction>?
	
	/// Returns asociated with account chatroom, or create new, in viewContext
	func chatroomWith(_ account: CoreDataAccount) -> Chatroom
	
	
	// MARK: - Sending messages
	func sendMessage(_ message: AdamantMessage, recipientId: String, completion: @escaping (ChatsProviderResult) -> Void )
	
	// MARK: - Tools
	func validateMessage(_ message: AdamantMessage) -> ValidateMessageResult
}
