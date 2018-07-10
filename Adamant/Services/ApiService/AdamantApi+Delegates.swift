//
//  AdamantApi+Delegates.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension AdamantApiService.ApiCommands {
    static let Delegates = (
        root: "/api/delegates",
        getDelegates: "/api/delegates",
        getVotes: "/api/accounts/delegates",
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
                            var delegate = delegate
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
                if let fIndex = nextForgers.delegates.index(of: delegate.publicKey) {
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
            endpoint = try buildUrl(path: ApiCommands.Delegates.getVotes, queryItems: [URLQueryItem(name: "address", value: address)])
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
            if let index = delegates.index(of: delegate) {
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
