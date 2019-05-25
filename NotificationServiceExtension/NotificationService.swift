//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 22/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    // MARK: - Store keys
    private struct StoreKeys {
        static let nodes = "nodesSource.nodes"
        static let passphrase = "accountService.passphrase"
        
        private init() {}
    }
    
    // MARK: - Hanlder
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent,
            let txnId = bestAttemptContent.userInfo["txn-id"] as? String,
            let pushRecipient = bestAttemptContent.userInfo["push-recipient"] as? String else {
            contentHandler(request.content)
            return
        }
        
        // MARK: 0. Getting services
        let securedStore = KeychainStore()
        let core = NativeAdamantCore()
        
        // No passphrase - no point of trying to get and decode
        guard let passphrase = securedStore.get(StoreKeys.passphrase),
            let keypair = core.createKeypairFor(passphrase: passphrase) else {
                contentHandler(bestAttemptContent)
                return
        }
        
        // MARK: 1. Nodes
        var nodes: [Node]
        
        if let raw = securedStore.get(StoreKeys.nodes), let data = raw.data(using: String.Encoding.utf8) {
            do {
                nodes = try JSONDecoder().decode([Node].self, from: data)
            } catch {
                nodes = AdamantResources.nodes
            }
        } else {
            nodes = AdamantResources.nodes
        }
        
        // MARK: 2. Get the transaction

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
                components.queryItems = [URLQueryItem(name: "id", value: txnId)]
                
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
        
        guard var transaction = response?.model else {
            contentHandler(bestAttemptContent)
            return
        }
        
        // ******
        // Waiting for API...
        // ******
        var collection: ServerCollectionResponse<Transaction>? = nil
        
        do {
            guard var components = URLComponents(url: nodeUrl, resolvingAgainstBaseURL: false) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            components.path = "/api/chats/get"
            components.queryItems = [URLQueryItem(name: "isIn", value: pushRecipient),
                                     URLQueryItem(name: "orderBy", value: "timestamp:asc"),
                                     URLQueryItem(name: "fromHeight", value: "\(transaction.height - 1)"),
                                     URLQueryItem(name: "limit", value: "1"),
            ]
            
            if let url = components.url {
                let data = try Data(contentsOf: url)
                collection = try JSONDecoder().decode(ServerCollectionResponse<Transaction>.self, from: data)
            }
        } catch {
            contentHandler(bestAttemptContent)
            return
        }
        
        if let t = collection?.collection?.first {
            transaction = t
        } else {
            contentHandler(bestAttemptContent)
            return
        }

        
        // https://endless.adamant.im/api/chats/get?isIn=U2279741505997340299&orderBy=timestamp:asc&fromHeight=8979346&limit=1
        
        // ******
        // Waiting for API...
        // ******
        
        
        // MARK: 3. Working on transaction
        let partner: String
        let partnerPublicKey: String
        
        if transaction.senderId == pushRecipient {
            partner = transaction.recipientId
            partnerPublicKey = transaction.recipientPublicKey ?? keypair.publicKey
        } else {
            partner = transaction.senderId
            partnerPublicKey = transaction.senderPublicKey
        }
        
        switch transaction.type {
        // MARK: Messages
        case .chatMessage:
            guard let chat = transaction.asset.chat,
                let message = core.decodeMessage(rawMessage: chat.message,
                                                 rawNonce: chat.ownMessage,
                                                 senderPublicKey: partnerPublicKey,
                                                 privateKey: keypair.privateKey) else {
                break
            }
            
            switch chat.type {
                
            // MARK: Simple messages
            case .messageOld:
                fallthrough
            case .message:
                bestAttemptContent.title = partner
                bestAttemptContent.body = message
            
            // MARK: Rich messages
            case .richMessage:
                break
                
            case .unknown: break
            case .signal: break
            }
            
        // MARK: Transfers
        case .send:
            break
            
        default:
            break
        }
        
        // MARK: Other configurations
        bestAttemptContent.threadIdentifier = partner
        
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
