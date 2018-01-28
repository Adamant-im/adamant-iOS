//
//  ChatDataProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData


/// ChatDataProvider Status
///
/// - notSynced: Just initiated, not yet synced.
/// - updating: Currently updating.
/// - upToDate: Synced.
/// - errorSyncing: Errored while syncing.
enum ProviderStatus {
	case disabled, updating, upToDate, errorSyncing
}

extension Notification.Name {
	/// Raised, when new chat transactions received.
	static let adamantChatProviderNewTransactions = Notification.Name("adamantChatProviderNewTransactions")
	
	/// Raised, when syncing failed.
	static let adamantChatProviderUpdateFailed = Notification.Name("adamantChatProviderUpdateFailed")
}

protocol ChatDataProvider {
	// MARK: - Syncing chats
	func reloadChats()
	func updateChats()
	func reset()
	
	// MARK: - Status
	var status: ProviderStatus { get }
	var autoupdate: Bool { get set }
	
	/// Default = 3 seconds
	var autoupdateInterval: TimeInterval { get set }
	
	// MARK: - Getting chats and messages
	func newChatroom(with address: String) -> Chatroom
	func getChatroomsController() -> NSFetchedResultsController<Chatroom>?
	func getChatController(for: Chatroom) -> NSFetchedResultsController<ChatTransaction>?
	
	// MARK: - Sending messages
	func sendTextMessage(recipientId: String, text: String)
	
	// MARK: - Tools
	func isValidMessage(text: String) -> Bool
}
