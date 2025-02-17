//
//  AdamantApi+Delegates.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

public extension ApiCommands {
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
    public func getDelegates(limit: Int) async -> ApiServiceResult<[Delegate]> {
        await getDelegates(limit: limit, offset: .zero, currentDelegates: [Delegate]())
    }
    
    public func getDelegates(
        limit: Int,
        offset: Int,
        currentDelegates: [Delegate]
    ) async -> ApiServiceResult<[Delegate]> {
        let response: ApiServiceResult<ServerCollectionResponse<Delegate>>
        response = await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Delegates.getDelegates,
                method: .get,
                parameters: ["limit": String(limit), "offset": String(offset)],
                encoding: .url
            )
        }
        
        let result = response.flatMap { $0.resolved() }
        guard let delegates = try? result.get() else { return result }
        let currentDelegates = currentDelegates + delegates
        
        if delegates.count < limit {
            return .success(currentDelegates)
        } else {
            return await getDelegates(
                limit: limit,
                offset: offset + limit,
                currentDelegates: currentDelegates
            )
        }
    }
    
    public func getDelegatesWithVotes(for address: String, limit: Int) async -> ApiServiceResult<[Delegate]> {
        let response = await getVotes(for: address)
        
        switch response {
        case let .success(delegates):
            let votes = delegates.map { $0.address }
            let delegatesResponse = await getDelegates(limit: limit)
            
            return delegatesResponse.map { delegates in
                var delegatesWithVotes = [Delegate]()
                
                delegates.forEach { delegate in
                    delegate.voted = votes.contains(delegate.address)
                    delegatesWithVotes.append(delegate)
                }
                
                return delegatesWithVotes
            }
        case let .failure(error):
            return .failure(error)
        }
    }
    
    public func getForgedByAccount(publicKey: String) async -> ApiServiceResult<DelegateForgeDetails> {
        await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Delegates.getForgedByAccount,
                method: .get,
                parameters: ["generatorPublicKey": publicKey],
                encoding: .url
            )
        }
    }
    
    public func getForgingTime(for delegate: Delegate) async -> ApiServiceResult<Int> {
        await getNextForgers().map { nextForgers in
            var forgingTime = -1
            if let fIndex = nextForgers.delegates.firstIndex(of: delegate.publicKey) {
                forgingTime = fIndex * 10
            }
            return forgingTime
        }
    }
    
    private func getDelegatesCount() async -> ApiServiceResult<DelegatesCountResult> {
        await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Delegates.getDelegatesCount
            )
        }
    }
    
    private func getNextForgers() async -> ApiServiceResult<NextForgersResult> {
        await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Delegates.getNextForgers,
                method: .get,
                parameters: ["limit": "\(101)"],
                encoding: .url
            )
        }
    }
    
    public func getVotes(for address: String) async -> ApiServiceResult<[Delegate]> {
        let response: ApiServiceResult<ServerCollectionResponse<Delegate>>
        response = await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Delegates.votes,
                method: .get,
                parameters: ["address": address],
                encoding: .url
            )
        }
        
        return response.map { $0.collection ?? .init() }
    }
    
    public func voteForDelegates(
        from address: String,
        keypair: Keypair,
        votes: [DelegateVote],
        date: Date
    ) async -> ApiServiceResult<Bool> {
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
        let transaction = NormalizedTransaction(
            type: .vote,
            amount: .zero,
            senderPublicKey: keypair.publicKey,
            requesterPublicKey: nil,
            date: date,
            recipientId: address,
            asset: TransactionAsset(votes: votesAsset)
        )
        
        guard let transaction = adamantCore.makeSignedTransaction(
            transaction: transaction,
            senderId: address,
            keypair: keypair
        ) else {
            return .failure(.internalError(error: InternalAPIError.signTransactionFailed))
        }
        
        return await sendDelegateVoteTransaction(
            path: ApiCommands.Delegates.votes,
            transaction: transaction
        )
    }
    
    // MARK: - Private methods
    
    private func getBlocks() async -> ApiServiceResult<[Block]> {
        let response: ApiServiceResult<ServerCollectionResponse<Block>> = await request { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: ApiCommands.Delegates.getBlocks,
                method: .get,
                parameters: ["orderBy": "height:desc", "limit": "\(101)"],
                encoding: .url
            )
        }
        
        return response.flatMap { $0.resolved() }
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
