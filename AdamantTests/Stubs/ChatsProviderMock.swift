//
//  ChatsProviderMock.swift
//  Adamant
//
//  Created by Christian Benua on 28.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import CommonKit
import CoreData

final actor ChatsProviderMock: ChatsProvider {
    var receivedLastHeight: Int64?
    
    var readedLastHeight: Int64?
    
    var isInitiallySynced: Bool = false
    
    var blockList: [String] = []
    
    var roomsMaxCount: Int?
    
    var roomsLoadedCount: Int?
    
    var chatMaxMessages: [String: Int] = [:]
    
    var chatLoadedMessages: [String : Int] = [:]
    
    var invokedAddUnconfirmed: Bool = false
    var invokedAddUnconfirmedCount: Int = 0
    var invokedAddUnconfirmedParameters: (transactionId: UInt64, objectId: NSManagedObjectID)?
    
    func addUnconfirmed(transactionId: UInt64, managedObjectId: NSManagedObjectID) {
        invokedAddUnconfirmed = true
        invokedAddUnconfirmedCount += 1
        invokedAddUnconfirmedParameters = (transactionId, managedObjectId)
    }
    
    // Unimplemented
    
    var chatLoadingStatusPublisher: AnyObservable<[String: ChatRoomLoadingStatus]> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getChatroom(for adm: String) -> Chatroom? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getChatroomsController() -> NSFetchedResultsController<Chatroom> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getChatRooms(offset: Int?) async {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getChatMessages(with addressRecipient: String, offset: Int?) async {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func isChatLoading(with addressRecipient: String) -> Bool {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func isChatLoaded(with addressRecipient: String) -> Bool {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func loadTransactionsUntilFound(_ transactionId: String, recipient: String) async throws {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getUnreadMessagesController() -> NSFetchedResultsController<ChatTransaction> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func update(notifyState: Bool) async -> ChatsProviderResult? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func sendMessage(_ message: AdamantMessage, recipientId: String) async throws -> ChatTransaction {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func sendMessage(_ message: AdamantMessage, recipientId: String, from chatroom: Chatroom?) async throws -> ChatTransaction {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func retrySendMessage(_ message: ChatTransaction) async throws {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func sendFileMessageLocally(_ message: AdamantMessage, recipientId: String, from chatroom: Chatroom?) async throws -> String {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func sendFileMessage(_ message: AdamantMessage, recipientId: String, transactionLocalyId: String, from chatroom: Chatroom?) async throws -> ChatTransaction {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func updateTxMessageContent(txId: String, richMessage: any RichMessage) throws {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func setTxMessageStatus(txId: String, status: MessageStatus) throws {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func cancelMessage(_ message: ChatTransaction) async throws {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func isMessageDeleted(id: String) -> Bool {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func validateMessage(_ message: AdamantMessage) -> ValidateMessageResult {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func blockChat(with address: String) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func removeMessage(with id: String) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func markChatAsRead(chatroom: Chatroom) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    @MainActor
    func removeChatPositon(for address: String) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    @MainActor
    func setChatPositon(for address: String, position: Double?) {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    @MainActor
    func getChatPositon(for address: String) -> Double? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func fakeReceived(message: AdamantMessage, senderId: String, date: Date, unread: Bool, silent: Bool, showsChatroom: Bool) async throws -> ChatTransaction {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getMessages(containing text: String, in chatroom: Chatroom?) -> [MessageTransaction]? {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func isTransactionUnique(_ transaction: RichMessageTransaction) -> Bool {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var state: State {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var stateObserver: AnyObservable<State> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func reload() async {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func reset() {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
