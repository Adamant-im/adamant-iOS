//
//  NotificationViewController.swift
//  TransferNotificationContentExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let passphraseStoreKey = "accountService.passphrase"
    
    // MARK: - Rich providers
    private lazy var adamantProvider: AdamantProvider = {
        return AdamantProvider()
    }()
    
    private lazy var richMessageProviders: [String: TransferNotificationContentProvider] = {
        return [EthProvider.richMessageType: EthProvider(),
                LskProvider.richMessageType: LskProvider(),
                DogeProvider.richMessageType: DogeProvider()]
    }()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var senderAddressLabel: UILabel!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var senderImageView: UIImageView!
    
    @IBOutlet weak var recipientAddressLabel: UILabel!
    @IBOutlet weak var recipientNameLabel: UILabel!
    @IBOutlet weak var recipientImageView: UIImageView!
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var currencySymbolLabel: UILabel!
    @IBOutlet weak var currencyImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
        // MARK: 0. Services
        let keychain = KeychainStore()
        let core = NativeAdamantCore()
        let avatarService = AdamantAvatarService()
        
        guard let passphrase = keychain.get(passphraseStoreKey), let keypair = core.createKeypairFor(passphrase: passphrase) else {
            showError()
            return
        }
        
        // MARK: 1. Get the transaction
        let trs: Transaction?
        if let transactionRaw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transaction] as? String, let data = transactionRaw.data(using: .utf8) {
            trs = try? JSONDecoder().decode(Transaction.self, from: data)
        } else {
            guard let id = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transactionId] as? String else {
                showError()
                return
            }
            
            let api = ExtensionsApi(keychainStore: keychain)
            trs = api.getTransaction(by: id)
        }
        
        guard let transaction = trs else {
            showError()
            return
        }
        
        // MARK: 2.1 Variables for UI
        let senderAddress = transaction.senderId
        let recipientAddress = transaction.recipientId
        let date = transaction.date
        let comments: String?
        let amount: Decimal
        let provider: TransferNotificationContentProvider
        
        // MARK: 2.2 Working on transaction
        switch transaction.type {
        case .send:
            amount = transaction.amount
            comments = nil
            provider = adamantProvider
            
        case .chatMessage:
            guard let chat = transaction.asset.chat else {
                showError()
                return
            }
            
            let message: String
            if let raw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.decodedMessage] as? String {
                message = raw
            } else {
                guard let raw = core.decodeMessage(rawMessage: chat.message, rawNonce: chat.ownMessage, senderPublicKey: transaction.senderPublicKey, privateKey: keypair.privateKey) else {
                    showError()
                    return
                }
                message = raw
            }
            
            // Adamant 'transfer with comment'
            switch chat.type {
            case .messageOld: fallthrough
            case .message:
                comments = message
                amount = transaction.amount
                provider = adamantProvider
                
            // Rich message
            case .richMessage:
                guard let data = message.data(using: String.Encoding.utf8),
                    let richContent = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String:String],
                    let key = richContent[RichContentKeys.type]?.lowercased(),
                    let p = richMessageProviders[key] else {
                        showError()
                        return
                }
                
                provider = p
                
                if let raw = richContent[RichContentKeys.transfer.comments], raw.count > 0 {
                    comments = raw
                } else {
                    comments = nil
                }
                
                if let raw = richContent[RichContentKeys.transfer.amount], let decimal = Decimal(string: raw) {
                    amount = decimal
                } else {
                    amount = 0
                }
                
            default:
                showError()
                return
            }
            
        default:
            showError()
            return
        }
        
        // MARK: 3. Setting up UI
        
        senderAddressLabel.text = senderAddress
        recipientAddressLabel.text = recipientAddress
        dateLabel.text = date.humanizedDateTime()

        currencyImageView.image = provider.currencyLogoLarge
        amountLabel.text = AdamantBalanceFormat.full.format(amount)
        currencySymbolLabel.text = provider.currencySymbol
        
        if let comments = comments {
            commentLabel.text = comments
        } else {
            commentLabel.isHidden = true
        }
        
        let group = DispatchGroup()
        
        var senderAvatar: UIImage! = nil
        var recipientAvatar: UIImage! = nil
        let size = Double(senderImageView.frame.height)
        
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            defer { group.leave() }
            senderAvatar = avatarService.avatar(for: transaction.senderPublicKey, size: size)
            recipientAvatar = avatarService.avatar(for: keypair.publicKey, size: size)
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.senderImageView.image = senderAvatar
            self.recipientImageView.image = recipientAvatar
            
            self.hideProgress()
        }
    }
    
    // MARK: - UI
    private func showError(error: String? = nil) {
        
    }
    
    private func hideProgress() {
        
    }
}
