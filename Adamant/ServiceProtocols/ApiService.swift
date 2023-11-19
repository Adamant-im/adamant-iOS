//
//  ApiService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Alamofire
import CommonKit

protocol ApiService {
    var preferredNodeIds: [UUID] { get }
    
    // MARK: - Accounts
    func healthCheck()
    func getAccount(byPassphrase passphrase: String) async -> ApiServiceResult<AdamantAccount>
    func getAccount(byPublicKey publicKey: String) async -> ApiServiceResult<AdamantAccount>
    func getAccount(byAddress address: String) async -> ApiServiceResult<AdamantAccount>
    
    // MARK: - Keys
    
    func getPublicKey(byAddress address: String) async -> ApiServiceResult<String>
    
    // MARK: - Transactions
    
    func getTransaction(id: UInt64) async -> ApiServiceResult<Transaction>
    func getTransaction(id: UInt64, withAsset: Bool) async -> ApiServiceResult<Transaction>
    
    func getTransactions(
        forAccount: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?
    ) async -> ApiServiceResult<[Transaction]>
    
    func getTransactions(
        forAccount account: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        limit: Int?,
        orderByTime: Bool?
    ) async -> ApiServiceResult<[Transaction]>
    
    // MARK: - Chats Rooms
    
    func getChatRooms(
        address: String,
        offset: Int?
    ) async -> ApiServiceResult<ChatRooms>
    
    func getChatMessages(
        address: String,
        addressRecipient: String,
        offset: Int?,
        limit: Int?
    ) async -> ApiServiceResult<ChatRooms>

    // MARK: - Funds
    
    func transferFunds(
        sender: String,
        recipient: String,
        amount: Decimal,
        keypair: Keypair
    ) async -> ApiServiceResult<UInt64>

    func transferFunds(
        transaction: UnregisteredTransaction
    ) async -> ApiServiceResult<UInt64>
    
    // MARK: - States
    
    /// - Returns: Transaction ID
    func store(
        key: String,
        value: String,
        type: StateType,
        sender: String,
        keypair: Keypair
    ) async -> ApiServiceResult<UInt64>
    
    func get(
        key: String,
        sender: String
    ) async -> ApiServiceResult<String?>
    
    // MARK: - Chats
    
    func getMessageTransactions(
        address: String,
        height: Int64?,
        offset: Int?
    ) async -> ApiServiceResult<[Transaction]>
    
    func sendTransaction(
        path: String,
        transaction: UnregisteredTransaction
    ) async -> ApiServiceResult<UInt64>

    func sendMessageTransaction(
        transaction: UnregisteredTransaction
    ) async -> ApiServiceResult<UInt64>
    
    // MARK: - Delegates
    
    /// Get delegates
    func getDelegates(limit: Int) async -> ApiServiceResult<[Delegate]>
    
    func getDelegatesWithVotes(
        for address: String,
        limit: Int
    ) async -> ApiServiceResult<[Delegate]>
    
    /// Get delegate forge details
    func getForgedByAccount(
        publicKey: String
    ) async -> ApiServiceResult<DelegateForgeDetails>
    
    /// Get delegate forgeing time
    func getForgingTime(
        for delegate: Delegate
    ) async -> ApiServiceResult<Int>
    
    /// Send vote transaction for delegates
    func voteForDelegates(
        from address: String,
        keypair: Keypair,
        votes: [DelegateVote]
    ) async -> ApiServiceResult<Bool>
}
