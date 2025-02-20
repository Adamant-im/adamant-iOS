//
//  AdamantApiServiceProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 28.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class AdamantApiServiceProtocolMock: AdamantApiServiceProtocol {
    
    var invokedTransferFunds: Bool = false
    var invokedTransferFundsCount: Int = 0
    var stubbedTransferFundsResult: ApiServiceResult<UInt64>!

    func transferFunds(transaction: UnregisteredTransaction) async -> ApiServiceResult<UInt64> {
        invokedTransferFunds = true
        invokedTransferFundsCount += 1
        
        return stubbedTransferFundsResult
    }
    
    var invokedSendMessageTransaction: Bool = false
    var invokedSendMessageTransactionCount: Int = 0
    var invokedSendMessageTransactionParameters: UnregisteredTransaction?
    var stubbedSendMessageTransactionResult: ApiServiceResult<UInt64>!
    
    func sendMessageTransaction(transaction: UnregisteredTransaction) async -> ApiServiceResult<UInt64> {
        invokedSendMessageTransaction = true
        invokedSendMessageTransactionCount += 1
        invokedSendMessageTransactionParameters = transaction
        
        return stubbedSendMessageTransactionResult
    }
    
    // Not implemented methods
    
    func getAccount(byPassphrase passphrase: String) async -> ApiServiceResult<AdamantAccount> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getAccount(byPublicKey publicKey: String) async -> ApiServiceResult<AdamantAccount> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getAccount(byAddress address: String) async -> ApiServiceResult<AdamantAccount> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getPublicKey(byAddress address: String) async -> ApiServiceResult<String> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getTransaction(id: UInt64) async -> ApiServiceResult<Transaction> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getTransaction(id: UInt64, withAsset: Bool) async -> ApiServiceResult<Transaction> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getTransactions(forAccount: String, type: TransactionType, fromHeight: Int64?, offset: Int?, limit: Int?, waitsForConnectivity: Bool) async -> ApiServiceResult<[Transaction]> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getTransactions(forAccount account: String, type: TransactionType, fromHeight: Int64?, offset: Int?, limit: Int?, orderByTime: Bool?, waitsForConnectivity: Bool) async -> ApiServiceResult<[Transaction]> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getChatRooms(address: String, offset: Int?, waitsForConnectivity: Bool) async -> ApiServiceResult<ChatRooms> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getChatMessages(address: String, addressRecipient: String, offset: Int?, limit: Int?) async -> ApiServiceResult<ChatRooms> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func transferFunds(sender: String, recipient: String, amount: Decimal, keypair: Keypair, date: Date) async -> ApiServiceResult<UInt64> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func store(_ model: KVSValueModel, date: Date) async -> ApiServiceResult<UInt64> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func get(key: String, sender: String) async -> ApiServiceResult<String?> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getMessageTransactions(address: String, height: Int64?, offset: Int?, waitsForConnectivity: Bool) async -> ApiServiceResult<[Transaction]> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func sendTransaction(path: String, transaction: UnregisteredTransaction) async -> ApiServiceResult<UInt64> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getDelegates(limit: Int) async -> ApiServiceResult<[Delegate]> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getDelegatesWithVotes(for address: String, limit: Int) async -> ApiServiceResult<[Delegate]> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getForgedByAccount(publicKey: String) async -> ApiServiceResult<DelegateForgeDetails> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getForgingTime(for delegate: Delegate) async -> ApiServiceResult<Int> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func voteForDelegates(from address: String, keypair: Keypair, votes: [DelegateVote], date: Date) async -> ApiServiceResult<Bool> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var nodesInfo: NodesListInfo {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var nodesInfoPublisher: AnyObservable<NodesListInfo> {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func healthCheck() {
        fatalError("\(#file).\(#function) is not implemented")
    }
}
