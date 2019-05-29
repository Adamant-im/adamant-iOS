//
//  NotificationViewController.swift
//  MessageNotificationContentExtension
//
//  Created by Anokhov Pavel on 29/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    private let passphraseStoreKey = "accountService.passphrase"
    private let sizeWithoutMessageLabel: CGFloat = 119.0
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var senderAvatarImageView: UIImageView!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var senderAddressLabel: UILabel!
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        senderAvatarImageView.tintColor = UIColor.adamant.primary
        senderNameLabel.text = ""
        senderAddressLabel.text = ""
        messageLabel.text = ""
        dateLabel.text = ""
    }
    
    func didReceive(_ notification: UNNotification) {
        // MARK: 0. Necessary services
        let avatarService = AdamantAvatarService()
        var keychainStore: KeychainStore? = nil
        
        // MARK: 1. Get the transaction
        let trs: Transaction?
        if let transactionRaw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transaction] as? String, let data = transactionRaw.data(using: .utf8) {
            trs = try? JSONDecoder().decode(Transaction.self, from: data)
        } else {
            guard let id = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transactionId] as? String else {
                showError()
                return
            }
            
            let store = KeychainStore()
            keychainStore = store
            let api = ExtensionsApi(keychainStore: store)
            trs = api.getTransaction(by: id)
        }
        
        guard let transaction = trs else {
            showError()
            return
        }
        
        // MARK: 2. Working with transaction
        
        let message: String
        if let raw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.decodedMessage] as? String {
            message = raw
        } else {
            if keychainStore == nil {
                keychainStore = KeychainStore()
            }
            
            let core = NativeAdamantCore()
            guard let passphrase = keychainStore!.get(passphraseStoreKey),
                let keypair = core.createKeypairFor(passphrase: passphrase),
                let chat = transaction.asset.chat,
                let raw = core.decodeMessage(rawMessage: chat.message,
                                             rawNonce: chat.ownMessage,
                                             senderPublicKey: transaction.senderPublicKey,
                                             privateKey: keypair.privateKey) else {
                showError()
                return
            }
            
            message = raw
        }
        
        // MARK: 3. Setting UI
        
        let senderName: String? = nil   // TODO:
        
        if let name = senderName {
            senderNameLabel.text = name
            senderAddressLabel.text = transaction.senderId
        } else {
            senderNameLabel.text = transaction.senderId
            senderAddressLabel.text = nil
        }
        
        senderAvatarImageView.image = avatarService.avatar(for: transaction.senderPublicKey, size: Double(senderAvatarImageView.frame.height))
        messageLabel.text = message
        dateLabel.text = transaction.date.humanizedDateTime()
        
        // MARK: 4. View size
        messageLabel.setNeedsLayout()
        messageLabel.layoutIfNeeded()
        preferredContentSize = CGSize(width: view.frame.width, height: sizeWithoutMessageLabel + messageLabel.frame.height)
        view.setNeedsUpdateConstraints()
        view.setNeedsLayout()
    }

    // MARK: - UI
    private func showError() {
        
    }
}
