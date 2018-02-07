//
//  ChatsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

enum ChatsProviderError: Error {
	case notLogged
	case serverError(Error)
	case accountNotFound(String)
}

extension Notification.Name {
	static let adamantChatsProviderNewChatroom = Notification.Name("adamantChatsProviderNewChatroom")
	static let adamantChatsProviderNewTransactions = Notification.Name("adamantChatsProviderNewTransactions")
}

protocol ChatsProvider: DataProvider {
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>?
	func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction>?
	
	/// Returns asociated with account chatroom, or create new, in viewContext
	func chatroomWith(_ account: CoreDataAccount) -> Chatroom
}
