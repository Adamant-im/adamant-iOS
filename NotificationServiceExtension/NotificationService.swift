//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Anokhov Pavel on 22/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    private let passphraseStoreKey = "accountService.passphrase"
    
    // MARK: - Rich providers
    private lazy var adamantProvider: AdamantProvider = {
        return AdamantProvider()
    }()
    
    /// Lazy constructors
    private lazy var richMessageProviders: [String: () -> RichMessageNotificationProvider] = {
        return [EthProvider.richMessageType: { EthProvider() },
                LskProvider.richMessageType: { LskProvider() },
                DogeProvider.richMessageType: { DogeProvider() }]
    }()
    
    // MARK: - Hanlder
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent,
            let txnId = bestAttemptContent.userInfo[AdamantNotificationUserInfoKeys.transactionId] as? String,
            let pushRecipient = bestAttemptContent.userInfo[AdamantNotificationUserInfoKeys.pushRecipient] as? String else {
            contentHandler(request.content)
            return
        }
        
        // MARK: 1. Getting services
        let securedStore = KeychainStore()
        let core = NativeAdamantCore()
        
        // No passphrase - no point of trying to get and decode
        guard let passphrase = securedStore.get(passphraseStoreKey),
            let keypair = core.createKeypairFor(passphrase: passphrase) else {
                contentHandler(bestAttemptContent)
                return
        }
        
        // MARK: 2. Get transaction
        let api = ExtensionsApi(keychainStore: securedStore)
        guard let transaction = api.getTransaction(by: txnId) else {
            contentHandler(bestAttemptContent)
            return
        }
        
        // MARK: 3. Working on transaction
        let partner: String
        let partnerPublicKey: String
        var decodedMessage: String? = nil
        
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
            
            decodedMessage = message
            
            switch chat.type {
            // MARK: Simple messages
            case .messageOld:
                fallthrough
            case .message:
                if transaction.amount > 0 { // ADM Transfer with comments
                    handleAdamantTransfer(notificationContent: bestAttemptContent, partner: partner, amount: transaction.amount, comment: message)
                } else { // Message
                    bestAttemptContent.title = partner
                    bestAttemptContent.body = message
                    bestAttemptContent.categoryIdentifier = AdamantNotificationCategories.message
                }
            
            // MARK: Rich messages
            case .richMessage:
                guard let data = message.data(using: String.Encoding.utf8),
                    let richContent = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String:String],
                    let key = richContent[RichContentKeys.type]?.lowercased(),
                    let provider = richMessageProviders[key]?(),
                    let content = provider.notificationContent(for: transaction, partner: partner, richContent: richContent) else {
                        bestAttemptContent.title = partner
                        bestAttemptContent.body = message
                        bestAttemptContent.categoryIdentifier = AdamantNotificationCategories.message
                        break
                }
                
                bestAttemptContent.title = content.title
                bestAttemptContent.body = content.body
                
                if let subtitle = content.subtitle { bestAttemptContent.subtitle = subtitle }
                if let attachments = content.attachments { bestAttemptContent.attachments = attachments }
                if let categoryIdentifier = content.categoryIdentifier { bestAttemptContent.categoryIdentifier = categoryIdentifier }
                
            case .unknown: break
            case .signal: break
            }
            
        // MARK: Transfers
        case .send:
            handleAdamantTransfer(notificationContent: bestAttemptContent, partner: partner, amount: transaction.amount, comment: nil)
            
        default:
            break
        }
        
        // MARK: Other configurations
        bestAttemptContent.threadIdentifier = partner
        
        // Caching downloaded transaction, to avoid downloading ang decoding it in ContentExtensions
        if let data = try? JSONEncoder().encode(transaction), let transactionRaw = String(data: data, encoding: .utf8) {
            bestAttemptContent.userInfo[AdamantNotificationUserInfoKeys.transaction] = transactionRaw
        }
        bestAttemptContent.userInfo[AdamantNotificationUserInfoKeys.decodedMessage] = decodedMessage
        
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func handleAdamantTransfer(notificationContent: UNMutableNotificationContent, partner: String, amount: Decimal, comment: String?) {
        guard let content = adamantProvider.notificationContent(partner: partner, amount: amount, comment: comment) else {
            return
        }
        
        notificationContent.title = content.title
        notificationContent.body = content.body
        
        if let subtitle = content.subtitle {
            notificationContent.subtitle = subtitle
        }
        
        if let attachments = content.attachments {
            notificationContent.attachments = attachments
        }
        
        notificationContent.categoryIdentifier = AdamantNotificationCategories.transfer
    }
}
