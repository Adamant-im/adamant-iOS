//
//  ApiServiceStub.swift
//  AdamantTests
//
//  Created by Andrey on 14.08.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import Alamofire
@testable import Adamant

final class ApiServiceStub: ApiService {
    let defaultResponseDispatchQueue: DispatchQueue = .default
    let lastRequestTimeDelta: TimeInterval? = nil
    let currentNode: Node? = nil
    
    func getNodeVersion(url: URL, completion: @escaping (ApiServiceResult<NodeVersion>) -> Void) {}
    
    func getNodeStatus(url: URL, completion: @escaping (ApiServiceResult<NodeStatus>) -> Void) -> DataRequest? { nil }
    
    func getAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {}
    
    func getAccount(byPublicKey publicKey: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {}
    
    func getAccount(byAddress address: String, completion: @escaping (ApiServiceResult<AdamantAccount>) -> Void) {}
    
    func getPublicKey(byAddress address: String, completion: @escaping (ApiServiceResult<String>) -> Void) {}
    
    func getTransaction(id: UInt64, completion: @escaping (ApiServiceResult<Transaction>) -> Void) {}
    
    func getTransactions(forAccount: String, type: TransactionType, fromHeight: Int64?, offset: Int?, limit: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void) {}
    
    func getChatRooms(address: String, offset: Int?, completion: @escaping (ApiServiceResult<ChatRooms>) -> Void) {}
    
    func getChatMessages(address: String, addressRecipient: String, offset: Int?, completion: @escaping (ApiServiceResult<ChatRooms>) -> Void) {}
    
    func transferFunds(sender: String, recipient: String, amount: Decimal, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {}
    
    func store(key: String, value: String, type: StateType, sender: String, keypair: Keypair, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {}
    
    func get(key: String, sender: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {}
    
    func getMessageTransactions(address: String, height: Int64?, offset: Int?, completion: @escaping (ApiServiceResult<[Transaction]>) -> Void) {}
    
    func sendMessage(senderId: String, recipientId: String, keypair: Keypair, message: String, type: ChatType, nonce: String, amount: Decimal?, completion: @escaping (ApiServiceResult<UInt64>) -> Void) {}
    
    func getDelegates(limit: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void) {}
    
    func getDelegatesWithVotes(for address: String, limit: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void) {}
    
    func getForgedByAccount(publicKey: String, completion: @escaping (ApiServiceResult<DelegateForgeDetails>) -> Void) {}
    
    func getForgingTime(for delegate: Delegate, completion: @escaping (ApiServiceResult<Int>) -> Void) {}
    
    func voteForDelegates(from address: String, keypair: Keypair, votes: [DelegateVote], completion: @escaping (ApiServiceResult<UInt64>) -> Void) {}
}
