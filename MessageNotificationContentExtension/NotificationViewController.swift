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
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var senderAvatarImageView: UIImageView!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var senderAddressLabel: UILabel!
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
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
        
        senderAddressLabel.text = transaction.senderId
        senderAvatarImageView.image = avatarService.avatar(for: transaction.senderPublicKey, size: Double(senderAvatarImageView.frame.height))
        messageLabel.text = message
        dateLabel.text = transaction.date.humanizedDateTime()
    }

    // MARK: - UI
    private func showError() {
        
    }
}
