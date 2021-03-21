//
//  AdamantApi+Delegates.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

extension AdamantApiService.ApiCommands {
    static let Delegates = (
        root: "/api/delegates",
        getDelegates: "/api/delegates",
        votes: "/api/accounts/delegates",
        getDelegatesCount: "/api/delegates/count",
        getForgedByAccount: "/api/delegates/forging/getForgedByAccount",
        getNextForgers: "/api/delegates/getNextForgers",
        getBlocks: "/api/blocks"
    )
}

extension AdamantApiService {
    func getDelegates(limit: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void) {
        self.getDelegates(limit: limit, offset: 0, currentDelegates: [Delegate](), completion: completion)
    }
    
    func getDelegates(limit: Int, offset: Int, currentDelegates: [Delegate], completion: @escaping (ApiServiceResult<[Delegate]>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.getDelegates, queryItems: [URLQueryItem(name: "limit", value: String(limit)),URLQueryItem(name: "offset", value: String(offset))])
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Delegate>>) in
            switch serverResponse {
            case .success(let delegates):
                if let delegates = delegates.collection {
                    var currentDelegates = currentDelegates
                    currentDelegates.append(contentsOf: delegates)
                    
                    if delegates.count < limit {
                        completion(.success(currentDelegates))
                    } else {
                        self.getDelegates(limit: limit, offset: offset+limit, currentDelegates: currentDelegates, completion: completion)
                    }
                } else {
                    completion(.failure(.serverError(error: "No delegates")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func getDelegatesWithVotes(for address: String, limit: Int, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void) {
        self.getVotes(for: address) { (result) in
            switch result {
            case .success(let delegates):
                let votes = delegates.map({ (delegate) -> String in
                    return delegate.address
                })
                
                self.getDelegates(limit: limit, completion: { (result) in
                    switch result {
                    case .success(let delegates):
                        var delegatesWithVotes = [Delegate]()
                        delegates.forEach({ (delegate) in
                            delegate.voted = votes.contains(delegate.address)
                            delegatesWithVotes.append(delegate)
                        })
                        
                        completion(.success(delegatesWithVotes))
                        break
                    case .failure(let error):
                        completion(.failure(.networkError(error: error)))
                    }
                })
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func getForgedByAccount(publicKey: String, completion: @escaping (ApiServiceResult<DelegateForgeDetails>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.getForgedByAccount, queryItems: [URLQueryItem(name: "generatorPublicKey", value: publicKey)])
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<DelegateForgeDetails>) in
            switch serverResponse {
            case .success(let details):
                completion(.success(details))
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func getForgingTime(for delegate: Delegate, completion: @escaping (ApiServiceResult<Int>) -> Void) {
        getNextForgers { (result) in
            switch result {
            case .success(let nextForgers):
                var forgingTime = -1
                if let fIndex = nextForgers.delegates.firstIndex(of: delegate.publicKey) {
                    forgingTime = fIndex * 10
                }
                completion(.success(forgingTime))
                
                
                break
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    private func getDelegatesCount(completion: @escaping (ApiServiceResult<DelegatesCountResult>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.getDelegatesCount)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<DelegatesCountResult>) in
            completion(serverResponse)
        }
    }
    
    private func getNextForgers(completion: @escaping (ApiServiceResult<NextForgersResult>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.getNextForgers, queryItems: [URLQueryItem(name: "limit", value: "\(101)")])
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<NextForgersResult>) in
            completion(serverResponse)
        }
    }
    
    func getVotes(for address: String, completion: @escaping (ApiServiceResult<[Delegate]>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.votes, queryItems: [URLQueryItem(name: "address", value: address)])
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Delegate>>) in
            switch serverResponse {
            case .success(let delegates):
                if let delegates = delegates.collection {
                    completion(.success(delegates))
                } else {
                    completion(.failure(.serverError(error: "No delegates")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    func voteForDelegates(from address: String, keypair: Keypair, votes: [DelegateVote], completion: @escaping (ApiServiceResult<UInt64>) -> Void) {
        self.sendingMsgTaskId = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.sendingMsgTaskId)
            self.sendingMsgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        // MARK: 0. Prepare
        var votesOrdered = votes
        _ = votesOrdered.partition {
            switch $0 {
            case .upvote: return false
            case .downvote: return true
            }
        }
        
        let votesAsset = VotesAsset(votes: votesOrdered)
        
        // MARK: 1. Create and sign transaction
        let asset = TransactionAsset(votes: votesAsset)
        let transaction = NormalizedTransaction(type: .vote,
                                                amount: 0,
                                                senderPublicKey: keypair.publicKey,
                                                requesterPublicKey: nil,
                                                date: Date(),
                                                recipientId: address,
                                                asset: asset)
        guard let signature = adamantCore.sign(transaction: transaction, senderId: address, keypair: keypair) else {
            completion(.failure(.internalError(message: "Failed to sign transaction", error: nil)))
            return
        }
        
        // MARK: 2. Prepare params
        let params: [String: Any] = [
            "type": transaction.type.rawValue,
            "amount": 0,
            "senderPublicKey": transaction.senderPublicKey,
            "senderId": transaction.recipientId ?? NSNull(),
            "timestamp": transaction.timestamp,
            "signature": signature,
            "recipientId": transaction.recipientId ?? NSNull(),
            "asset": [
                "votes": votesAsset.votes
            ]
        ]
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 3. Build endpoints
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.votes)
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        // MARK: 4. Send
        sendRequest(url: endpoint, method: .post, parameters: params, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerResponse>) in
            switch serverResponse {
            case .success(let response):
                if response.success {
                    completion(.success(1))
                } else {
                    completion(.failure(.serverError(error: response.error ?? "")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
            
            do {
                UIApplication.shared.endBackgroundTask(self.sendingMsgTaskId)
                self.sendingMsgTaskId = UIBackgroundTaskIdentifier.invalid
            }
        }
    }
    
    // MARK: - Private methods
    
    private func getBlocks(completion: @escaping (ApiServiceResult<[Block]>) -> Void) {
        // MARK: 1. Prepare
        let endpoint: URL
        do {
            endpoint = try buildUrl(path: ApiCommands.Delegates.getBlocks, queryItems:
                [URLQueryItem(name: "orderBy", value: "height:desc"),
                URLQueryItem(name: "limit", value: "\(101)")])
        } catch {
            let err = InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // MARK: 2. Make request
        sendRequest(url: endpoint, method: .get, encoding: .json, headers: headers) { (serverResponse: ApiServiceResult<ServerCollectionResponse<Block>>) in
            switch serverResponse {
            case .success(let blocks):
                if let blocks = blocks.collection {
                    completion(.success(blocks))
                } else {
                    completion(.failure(.serverError(error: "No delegates")))
                }
                
            case .failure(let error):
                completion(.failure(.networkError(error: error)))
            }
        }
    }
    
    private func getRoundDelegates(delegates: [String], height: UInt64) -> [String] {
        let currentRound = round(height)
        return delegates.filter({ (delegate) -> Bool in
            if let index = delegates.firstIndex(of: delegate) {
                return currentRound == round(height + UInt64(index) + 1)
            }
            return false
        })
    }
    
    private func round(_ height: UInt64?) -> UInt {
        if let height = height {
            return UInt(floor(Double(height) / 101) + (Double(height).truncatingRemainder(dividingBy: 101) > 0 ? 1 : 0))
        } else {
            return 0
        }
    }
}
