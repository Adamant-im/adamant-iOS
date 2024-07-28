//
//  ChatsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData
import CommonKit

// MARK: - Callbacks

enum ChatsProviderResult {
    case success
    case failure(ChatsProviderError)
}

enum ChatsProviderResultWithTransaction {
    case success(transaction: ChatTransaction)
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
    case notEnoughMoneyToSend
    case networkError
    case serverError(Error)
    case accountNotFound(String)
    case accountNotInitiated(String)
    case dependencyError(String)
    case transactionNotFound(id: String)
    case internalError(Error)
    case requestCancelled
    case invalidTransactionStatus
}

extension ChatsProviderError: RichError {
    var message: String {
        switch self {
        case .invalidTransactionStatus:
            return String.adamant.chat.cancelError
            
        case .notLogged:
            return String.adamant.sharedErrors.userNotLogged
            
        case .messageNotValid(let result):
            return result.localized
            
        case .notEnoughMoneyToSend:
            return .localized("ChatsProvider.Error.notEnoughMoney", comment: "ChatsProvider: Notify user that he doesn't have money to pay a message fee")
            
        case .networkError:
            return String.adamant.sharedErrors.networkError
            
        case .serverError(let error):
            return ApiServiceError.serverError(error: error.localizedDescription)
                .localizedDescription
            
        case .accountNotFound(let address):
            return AccountsProviderError.notFound(address: address).localized
            
        case .dependencyError(let message):
            return String.adamant.sharedErrors.internalError(message: message)
            
        case .transactionNotFound(let id):
            return String.localizedStringWithFormat(.localized("ChatsProvider.Error.TransactionNotFoundFormat", comment: "ChatsProvider: Transaction not found error. %@ for transaction's ID"), id)
            
        case .internalError(let error):
            return String.adamant.sharedErrors.internalError(message: error.localizedDescription)
            
        case .accountNotInitiated:
            return String.adamant.sharedErrors.accountNotInitiated
        
        case .requestCancelled:
            return String.adamant.sharedErrors.requestCancelled
        }
    }
    
    var internalError: Error? {
        switch self {
        case .internalError(let error), .serverError(let error):
            return error
            
        default:
            return nil
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .accountNotFound,
                .messageNotValid,
                .networkError,
                .notEnoughMoneyToSend,
                .accountNotInitiated,
                .requestCancelled,
                .invalidTransactionStatus,
                .notLogged:
            return .warning
            
        case .serverError, .transactionNotFound:
            return .error
            
        case .dependencyError,
             .internalError:
            return .internalError
        }
    }
}

enum ValidateMessageResult {
    case isValid
    case empty
    case tooLong
    
    var localized: String {
        switch self {
        case .isValid: return .localized("ChatsProvider.Validation.Passed", comment: "ChatsProvider: Validation passed, message is valid")
            
        case .empty:
            return .localized("ChatsProvider.Validation.MessageIsEmpty", comment: "ChatsProvider: Validation error: Message is empty")
            
        case .tooLong:
            return .localized("ChatsProvider.Validation.MessageTooLong", comment: "ChatsProvider: Validation error: Message is too long")
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    struct AdamantChatsProvider {
        /// Received new messagess. See AdamantUserInfoKey.ChatProvider
        static let newUnreadMessages = Notification.Name("adamant.chatsProvider.newUnreadMessages")

        static let initiallySyncedChanged = Notification.Name("adamant.chatsProvider.initialSyncChanged")

        static let initiallyLoadedMessages = Notification.Name("adamant.chatsProvider.initiallyLoadedMessages")
        
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
        
        static let initiallySynced = "adamant.chatsProvider.initiallySynced"
        
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
protocol ChatsProvider: DataProvider, Actor {
    // MARK: - Properties
    var receivedLastHeight: Int64? { get }
    var readedLastHeight: Int64? { get }
    var isInitiallySynced: Bool { get }
    var blockList: [String] { get }
    
    var roomsMaxCount: Int? { get }
    var roomsLoadedCount: Int? { get }
    
    var chatLoadingStatusPublisher: Published<[String : ChatRoomLoadingStatus]>.Publisher {
        get
    }
    
    var chatMaxMessages: [String: Int] { get }
    var chatLoadedMessages: [String: Int] { get }
    
    // MARK: - Getting chats and messages
    func getChatroom(for adm: String) -> Chatroom?
    func getChatroomsController() -> NSFetchedResultsController<Chatroom>
    @MainActor func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction>
    func getChatRooms(offset: Int?) async throws
    func getChatMessages(with addressRecipient: String, offset: Int?) async
    func isChatLoading(with addressRecipient: String) -> Bool
    func isChatLoaded(with addressRecipient: String) -> Bool
    
    func loadTransactionsUntilFound(
        _ transactionId: String,
        recipient: String
    )  async throws
    
    /// Unread messages controller. Sections by chatroom.
    func getUnreadMessagesController() -> NSFetchedResultsController<ChatTransaction>
    
    // ForceUpdate chats
    func update(notifyState: Bool) async -> ChatsProviderResult?
    
    // MARK: - Sending messages
    func sendMessage(_ message: AdamantMessage, recipientId: String) async throws -> ChatTransaction
    func sendMessage(_ message: AdamantMessage, recipientId: String, from chatroom: Chatroom?) async throws -> ChatTransaction
    func retrySendMessage(_ message: ChatTransaction) async throws
    
    // MARK: - Delete local message
    func cancelMessage(_ message: ChatTransaction) async throws
    func isMessageDeleted(id: String) -> Bool
    
    // MARK: - Tools
    func validateMessage(_ message: AdamantMessage) -> ValidateMessageResult
    func blockChat(with address: String)
    func removeMessage(with id: String)
    func markChatAsRead(chatroom: Chatroom)
    
    @MainActor func removeChatPositon(for address: String)
    @MainActor func setChatPositon(for address: String, position: Double?)
    @MainActor func getChatPositon(for address: String) -> Double?
    
    // MARK: - Unconfirmed Transaction
    func addUnconfirmed(transactionId: UInt64, managedObjectId: NSManagedObjectID)
    
    // MARK: - Fake messages
    func fakeSent(message: AdamantMessage, recipientId: String, date: Date, status: MessageStatus, showsChatroom: Bool, completion: @escaping (ChatsProviderResultWithTransaction) -> Void)
    
    func fakeReceived(
        message: AdamantMessage,
        senderId: String,
        date: Date,
        unread: Bool,
        silent: Bool,
        showsChatroom: Bool
    ) async throws -> ChatTransaction
    
    func fakeUpdate(status: MessageStatus, forTransactionId id: String, completion: @escaping (ChatsProviderResult) -> Void)
    
    // MARK: - Search
    func getMessages(containing text: String, in chatroom: Chatroom?) -> [MessageTransaction]?
    func isTransactionUnique(_ transaction: RichMessageTransaction) -> Bool
}
