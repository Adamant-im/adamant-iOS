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
    private let addressBookKey = "contact_list"
    private let nodesStoreKey = "nodesSource.nodes"
    let keychainStore: KeychainStore
    
    private(set) lazy var nodes: [Node] = {
        if let raw = keychainStore.get(nodesStoreKey), let data = raw.data(using: String.Encoding.utf8) {
            do {
                return try JSONDecoder().decode([Node].self, from: data)
            } catch {
                return AdamantResources.nodes
            }
        } else {
            return AdamantResources.nodes
        }
    }()
    
    private var currentNode: Node?
    
    private func selectNewNode() {
        currentNode = nodes.popLast()
    }
    
    // MARK: Cotr
    init(keychainStore: KeychainStore) {
        self.keychainStore = keychainStore
    }
    
    // MARK: - API
    
    // MARK: Transactions
    func getTransaction(by id: UInt64) -> Transaction? {
        // MARK: 1. Getting Transaction
        var response: ServerModelResponse<Transaction>?
        var nodeUrl: URL! = nil
        if currentNode == nil {
            selectNewNode()
        }
        
        repeat {
            guard let node = currentNode, let url = node.asURL() else {
                selectNewNode()
                continue
            }
            nodeUrl = url
            
            do {
                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    selectNewNode()
                    continue
                }
                
                components.path = "/api/transactions/get"
                components.queryItems = [URLQueryItem(name: "id", value: "\(id)"),
                                         URLQueryItem(name: "returnAsset", value: "1")]
                
                if let url = components.url {
                    let data = try Data(contentsOf: url)
                    response = try JSONDecoder().decode(ServerModelResponse<Transaction>.self, from: data)
                } else {
                    selectNewNode()
                    continue
                }
            } catch {
                selectNewNode()
                continue
            }
        } while response == nil && nodes.count > 0 // Try until we have a transaction, or we run out of nodes
        
        guard let transaction = response?.model else {
            return nil
        }
        
        // MARK: 2. Working on transaction
        
        // For old nodes - if /api/transaction/get doesn't return chat asset - get it from /api/chats/
        if transaction.type == .chatMessage, transaction.asset.chat == nil {
            do {
                guard var components = URLComponents(url: nodeUrl, resolvingAgainstBaseURL: false) else {
                    return nil
                }
                
                components.path = "/api/chats/get"
                components.queryItems = [URLQueryItem(name: "recipientId", value: transaction.recipientId),
                                         URLQueryItem(name: "orderBy", value: "timestamp:asc"),
                                         URLQueryItem(name: "fromHeight", value: "\(transaction.height - 1)")
                ]
                
                if let url = components.url {
                    let data = try Data(contentsOf: url)
                    let collection = try JSONDecoder().decode(ServerCollectionResponse<Transaction>.self, from: data)
                    return collection.collection?.first { $0.id == id }
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        } else {
            return transaction
        }
    }
    
    // MARK: Address book
    
    func getAddressBook(for address: String, core: NativeAdamantCore, keypair: Keypair) -> [String:ContactDescription]? {
        var response: ServerCollectionResponse<Transaction>?
        
        // Getting transaction
        repeat {
            guard let node = currentNode, let url = node.asURL() else {
                selectNewNode()
                continue
            }
            
            do {
                guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                    selectNewNode()
                    continue
                }
                
                components.path = "/api/states/get"
                components.queryItems = [URLQueryItem(name: "senderId", value: address),
                                         URLQueryItem(name: "orderBy", value: "timestamp:desc"),
                                         URLQueryItem(name: "key", value: addressBookKey)]
                
                if let url = components.url {
                    let data = try Data(contentsOf: url)
                    response = try JSONDecoder().decode(ServerCollectionResponse<Transaction>.self, from: data)
                } else {
                    selectNewNode()
                    continue
                }
            } catch {
                selectNewNode()
                continue
            }
        } while response == nil && nodes.count > 0 // Try until we have a transaction, or we run out of nodes
        
        // Working with transaction
        
        guard let collection = response?.collection,
            let object = collection.first?.asset.state?.value.toDictionary(),
            let message = object["message"] as? String,
            let nonce = object["nonce"] as? String else {
                return nil
        }
        
        // Decoding
        guard let decodedMessage = core.decodeValue(rawMessage: message, rawNonce: nonce, privateKey: keypair.privateKey),
            let rawJson = decodedMessage.matches(for: "\\{.*\\}").first,
            let contacts = rawJson.toDictionary()?["payload"] as? [String:Any] else {
                return nil
        }
        
        var result = [String:ContactDescription]()
        let decoder = JSONDecoder()
        
        for (key, value) in contacts {
            guard let data = try? JSONSerialization.data(withJSONObject: value, options: []),
                let description = try? decoder.decode(ContactDescription.self, from: data) else {
                continue
            }
            
            result[key] = description
        }
        
        if result.count > 0 {
            return result
        } else {
            return nil
        }
    }
}
