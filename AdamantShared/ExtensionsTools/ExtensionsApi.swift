//
//  ExtensionsApi.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

class ExtensionsApi {
    // MARK: Properties
    private let nodesStoreKey = "nodesSource.nodes"
    let keychainStore: KeychainStore
    
    // MARK: Cotr
    init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }
    
    // MARK: API
    func getTransaction(by id: String) -> Transaction? {
        // MARK: 1. Nodes
        var nodes: [Node]
        
        if let raw = keychainStore.get(nodesStoreKey), let data = raw.data(using: String.Encoding.utf8) {
            do {
                nodes = try JSONDecoder().decode([Node].self, from: data)
            } catch {
                nodes = AdamantResources.nodes
            }
        } else {
            nodes = AdamantResources.nodes
        }
        
        // MARK: 2. Getting Transaction
        var response: ServerModelResponse<Transaction>? = nil
        var nodeUrl: URL! = nil
        
        repeat {
            guard let node = nodes.popLast(), let url = node.asURL() else {
                continue
            }
            nodeUrl = url
            
            do {
                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    continue
                }
                
                components.path = "/api/transactions/get"
                components.queryItems = [URLQueryItem(name: "id", value: id)]
                
                if let url = components.url {
                    let data = try Data(contentsOf: url)
                    response = try JSONDecoder().decode(ServerModelResponse<Transaction>.self, from: data)
                } else {
                    continue
                }
            } catch {
                continue
            }
        } while response == nil && nodes.count > 0 // Try until we have a transaction, or we run out of nodes
        
        guard let transaction = response?.model else {
            return nil
        }
        
        // ******
        // Waiting for API...
        // ******
        
        if transaction.type == .chatMessage {
            do {
                guard var components = URLComponents(url: nodeUrl, resolvingAgainstBaseURL: false) else {
                    return nil
                }
                
                components.path = "/api/chats/get"
                components.queryItems = [URLQueryItem(name: "isIn", value: transaction.recipientId),
                                         URLQueryItem(name: "orderBy", value: "timestamp:asc"),
                                         URLQueryItem(name: "fromHeight", value: "\(transaction.height - 1)"),
                                         URLQueryItem(name: "limit", value: "1"),
                ]
                
                if let url = components.url {
                    let data = try Data(contentsOf: url)
                    let collection = try JSONDecoder().decode(ServerCollectionResponse<Transaction>.self, from: data)
                    return collection.collection?.first
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        } else {
            return transaction
        }
        
        // ******
        // Waiting for API...
        // ******
    }
}
