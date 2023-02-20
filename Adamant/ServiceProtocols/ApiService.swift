//
//  ApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Alamofire

// MARK: - Notifications
extension Notification.Name {
    enum ApiService {
        static let currentNodeUpdate = Notification.Name("adamant.apiService.currentNodeUpdate")
    }
}

// - MARK: ApiService
protocol ApiService: AnyObject {
    
    /// Default is async queue with .utilities priority.
    var defaultResponseDispatchQueue: DispatchQueue { get }
    
    /// Time interval between node (lhs) and client (rhs)
    /// Substract this from client time to get server time
    var lastRequestTimeDelta: TimeInterval? { get }
    
    var currentNodes: [Node] { get }
    
    // MARK: - Async/Await
    
    func sendRequest<Output: Decodable>(
        url: URLConvertible,
        method: HTTPMethod,
        parameters: Parameters?
    ) async throws -> Output
    
    func sendRequest<Output: Decodable>(
        url: URLConvertible,
        method: HTTPMethod,
        parameters: Parameters?,
        encoding: ParameterEncoding
    ) async throws -> Output
    
    func sendRequest(
        url: URLConvertible,
        method: HTTPMethod,
        parameters: Parameters?
    ) async throws -> Data
    
    func sendRequest(
        url: URLConvertible,
        method: HTTPMethod,
        parameters: Parameters?,
        encoding: ParameterEncoding
    ) async throws -> Data
    
    // MARK: - Peers
    
    func getNodeVersion(url: URL, completion: @escaping (ApiServiceResult<NodeVersion>) -> Void)
    
    // MARK: - Status
    
    @discardableResult
    func getNodeStatus(
        url: URL,
        completion: @escaping (ApiServiceResult<NodeStatus>) -> Void
    ) -> DataRequest?
    
    // MARK: - Accounts
    
    func getAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void)
    func getAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void)
    
    func getAccount(byPublicKey publicKey: String) async throws -> AdamantAccount
    
    func getAccount(
        byAddress address: String,
        completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void
    )
    
    func getAccount(byAddress address: String) async throws -> AdamantAccount
    
    // MARK: - Keys
    
    func getPublicKey(
        byAddress address: String,
        completion: @escaping (ApiServiceResult<String>) -> Void
    )
    
    // MARK: - Transactions
    
    func getTransaction(id: UInt64, completion: @escaping (ApiServiceResult<Transaction>) -> Void)
    
    func getTransaction(id: UInt64) async throws -> Transaction
    
    func getTransactions(
        forAccount: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?,
        completion: @escaping (ApiServiceResult<[Transaction]>) -> Void
    )
    
    func getTransactions(
        forAccount: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?
    ) async throws -> [Transaction]
    
    // MARK: - Chats Rooms
      
    func getChatRooms(
        address: String,
        offset: Int?,
        completion: @escaping (ApiServiceResult<ChatRooms>) -> Void
    )
    
    func getChatRooms(
        address: String,
        offset: Int?
    ) async throws -> ChatRooms
    
    func getChatMessages(
        address: String,
        addressRecipient: String,
        offset: Int?
    ) async throws -> ChatRooms

    // MARK: - Funds
    
    func transferFunds(
        sender: String,
        recipient: String,
        amount: Decimal,
        keypair: Keypair,
        completion: @escaping (ApiServiceResult<UInt64>) -> Void
    )
    
    func transferFunds(
        sender: String,
        recipient: String,
        amount: Decimal,
        keypair: Keypair
    ) async throws -> UInt64
    
    // MARK: - States
    
    /// - Returns: Transaction ID
    func store(
        key: String,
        value: String,
        type: StateType,
        sender: String,
        keypair: Keypair,
        completion: @escaping (ApiServiceResult<UInt64>) -> Void
    )
    
    func get(key: String, sender: String, completion: @escaping (ApiServiceResult<String?>) -> Void)
    
    func get(
        key: String,
        sender: String
    ) async throws -> String?
    
    // MARK: - Chats
    
    /// Get chat transactions (type 8)
    ///
    /// - Parameters:
    ///   - address: Transactions for specified account
    ///   - height: From this height. Minimal value is 1.
    func getMessageTransactions(
        address: String,
        height: Int64?,
        offset: Int?,
        completion: @escaping (ApiServiceResult<[Transaction]>) -> Void
    )
    
    func getMessageTransactions(address: String,
                                height: Int64?,
                                offset: Int?
    ) async throws -> [Transaction]
    
    /// Send text message
    ///   - completion: Contains processed transactionId, if success, or AdamantError, if fails.
    ///   - Returns: Signed unregistered transaction
    @discardableResult
    func sendMessage(
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        message: String,
        type: ChatType,
        nonce: String,
        amount: Decimal?,
        completion: @escaping (ApiServiceResult<UInt64>) -> Void
    ) -> UnregisteredTransaction?
    
    func sendTransaction(
        path: String,
        transaction: UnregisteredTransaction,
        completion: @escaping (ApiServiceResult<TransactionIdResponse>) -> Void
    )
    
    func createSendTransaction(
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        message: String,
        type: ChatType,
        nonce: String,
        amount: Decimal?
    ) -> UnregisteredTransaction?

    func sendTransaction(
        transaction: UnregisteredTransaction
    ) async throws -> UInt64
    
    // MARK: - Delegates
    
    /// Get delegates
    func getDelegates(limit: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void)
    
    func getDelegatesWithVotes(
        for address: String,
        limit: Int,
        completion: @escaping (ApiServiceResult<[Delegate]>) -> Void
    )
    
    /// Get delegate forge details
    func getForgedByAccount(
        publicKey: String,
        completion: @escaping (ApiServiceResult<DelegateForgeDetails>) -> Void
    )
    
    /// Get delegate forgeing time
    func getForgingTime(
        for delegate: Delegate,
        completion: @escaping (ApiServiceResult<Int>) -> Void
    )
    
    /// Send vote transaction for delegates
    func voteForDelegates(
        from address: String,
        keypair: Keypair,
        votes: [DelegateVote],
        completion: @escaping (ApiServiceResult<UInt64>) -> Void
    )
}
