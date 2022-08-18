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
}

extension ChatsProviderError: RichError {
    var message: String {
        switch self {
        case .notLogged:
            return String.adamantLocalized.sharedErrors.userNotLogged
            
        case .messageNotValid(let result):
            return result.localized
            
        case .notEnoughMoneyToSend:
            return NSLocalizedString("ChatsProvider.Error.notEnoughMoney", comment: "ChatsProvider: Notify user that he doesn't have money to pay a message fee")
            
        case .networkError:
            return String.adamantLocalized.sharedErrors.networkError
            
        case .serverError(let error):
            return ApiServiceError.serverError(error: error.localizedDescription).localized
            
        case .accountNotFound(let address):
            return AccountsProviderResult.notFound(address: address).localized
            
        case .dependencyError(let message):
            return String.adamantLocalized.sharedErrors.internalError(message: message)
            
        case .transactionNotFound(let id):
            return String.localizedStringWithFormat(NSLocalizedString("ChatsProvider.Error.TransactionNotFoundFormat", comment: "ChatsProvider: Transaction not found error. %@ for transaction's ID"), id)
            
        case .internalError(let error):
            return String.adamantLocalized.sharedErrors.internalError(message: error.localizedDescription)
            
        case .accountNotInitiated:
            return String.adamantLocalized.sharedErrors.accountNotInitiated
        
        case .requestCancelled:
            return String.adamantLocalized.sharedErrors.requestCancelled
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
                 .notLogged:
            return .warning
            
        case .dependencyError,
             .internalError,
             .serverError,
             .transactionNotFound:
            return .error
        }
    }
}

enum ValidateMessageResult {
    case isValid
    case empty
    case tooLong
    
    var localized: String {
        switch self {
        case .isValid: return NSLocalizedString("ChatsProvider.Validation.Passed", comment: "ChatsProvider: Validation passed, message is valid")
            
        case .empty:
            return NSLocalizedString("ChatsProvider.Validation.MessageIsEmpty", comment: "ChatsProvider: Validation error: Message is empty")
            
        case .tooLong:
            return NSLocalizedString("ChatsProvider.Validation.MessageTooLong", comment: "ChatsProvider: Validation error: Message is too long")
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    struct AdamantChatsProvider {
        /// Received new messagess. See AdamantUserInfoKey.ChatProvider
        static let newUnreadMessages = Notification.Name("adamant.chatsProvider.newUnreadMessages")

        static let initiallySyncedChanged = Notification.Name("adamant.chatsProvider.initialSyncChanged")

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
protocol ChatsProvider: DataProvider {
    // MARK: - Properties
    var receivedLastHeight: Int64? { get }
    var readedLastHeight: Int64? { get }
    var isInitiallySynced: Bool { get }
    
    var chatPositon: [String: Double] { get set }
    var blackList: [String] { get }
    
    var roomsMaxCount: Int? { get }
    var roomsLoadedCount: Int? { get }
    
    var isChatLoaded: [String: Bool] { get }
    var chatMaxMessages: [String: Int] { get }
    var chatLoadedMessages: [String: Int] { get }
    
    // MARK: - Getting chats and messages
    func getChatroomsController() -> NSFetchedResultsController<Chatroom>
    func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction>
    func getChatRooms(offset: Int?, completion: (() ->Void)?)
    func getChatMessages(with addressRecipient: String, offset: Int?, completion: ((Int) ->Void)?)
    
    /// Unread messages controller. Sections by chatroom.
    func getUnreadMessagesController() -> NSFetchedResultsController<ChatTransaction>
    
    // ForceUpdate chats
    func update()
    func update(completion: ((ChatsProviderResult?) -> Void)?)
    
    // MARK: - Sending messages
    func sendMessage(_ message: AdamantMessage, recipientId: String, completion: @escaping (ChatsProviderResultWithTransaction) -> Void )
    func sendMessage(_ message: AdamantMessage, recipientId: String, from chatroom: Chatroom?, completion: @escaping (ChatsProviderResultWithTransaction) -> Void )
    func retrySendMessage(_ message: ChatTransaction, completion: @escaping (ChatsProviderRetryCancelResult) -> Void)
    
    // MARK: - Delete local message
    func cancelMessage(_ message: ChatTransaction, completion: @escaping (ChatsProviderRetryCancelResult) -> Void )
    
    // MARK: - Tools
    func validateMessage(_ message: AdamantMessage) -> ValidateMessageResult
    func blockChat(with address: String)
    func removeMessage(with id: String)
    
    // MARK: - Unconfirmed Transaction
    func addUnconfirmed(transactionId: UInt64, managedObjectId: NSManagedObjectID)
    
    // MARK: - Fake messages
    func fakeSent(message: AdamantMessage, recipientId: String, date: Date, status: MessageStatus, showsChatroom: Bool, completion: @escaping (ChatsProviderResultWithTransaction) -> Void)
    func fakeReceived(message: AdamantMessage, senderId: String, date: Date, unread: Bool, silent: Bool, showsChatroom: Bool, completion: @escaping (ChatsProviderResultWithTransaction) -> Void)
    func fakeUpdate(status: MessageStatus, forTransactionId id: String, completion: @escaping (ChatsProviderResult) -> Void)
    
    // MARK: - Search
    func getMessages(containing text: String, in chatroom: Chatroom?) -> [MessageTransaction]?
    func isTransactionUnique(_ transaction: RichMessageTransaction) -> Bool
}
