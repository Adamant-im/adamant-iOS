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
    private let sizeWithoutMessageLabel: CGFloat = 123.0
    
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
        var extensionApi: ExtensionsApi? = nil
        var nativeCore: NativeAdamantCore? = nil
        var keypair: Keypair? = nil
        
        // MARK: 1. Get the transaction
        let trs: Transaction?
        if let transactionRaw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transaction] as? String, let data = transactionRaw.data(using: .utf8) {
            trs = try? JSONDecoder().decode(Transaction.self, from: data)
        } else {
            guard let raw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transactionId] as? String, let id = UInt64(raw) else {
                showError()
                return
            }
            
            let store = KeychainStore()
            let api = ExtensionsApi(keychainStore: store)
            trs = api.getTransaction(by: id)
            
            keychainStore = store
            extensionApi = api
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
            
            nativeCore = NativeAdamantCore()
            guard let passphrase = keychainStore!.get(passphraseStoreKey),
                let keys = nativeCore!.createKeypairFor(passphrase: passphrase),
                let chat = transaction.asset.chat,
                let raw = nativeCore!.decodeMessage(rawMessage: chat.message,
                                                    rawNonce: chat.ownMessage,
                                                    senderPublicKey: transaction.senderPublicKey,
                                                    privateKey: keys.privateKey) else {
                showError()
                return
            }
            
            message = raw
            keypair = keys
        }
        
        // MARK: 3. Names
        let senderName: String?
        
        // We have cached name
        if let name = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.partnerDisplayName] as? String {
            senderName = name
        }
        // No name, but we have flag - skip it
        else if let flag = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.partnerNoDislpayNameKey] as? String, flag == AdamantNotificationUserInfoKeys.partnerNoDisplayNameValue {
            senderName = nil
        }
        // No name, no flag - something broke. Check sender name, if we have a recipient address
        else if let recipient = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.pushRecipient] as? String {
            let keychain = keychainStore ?? KeychainStore()
            let core = nativeCore ?? NativeAdamantCore()
            let api: ExtensionsApi = extensionApi ?? ExtensionsApi(keychainStore: keychain)
            
            let key: Keypair?
            if let keypair = keypair {
                key = keypair
            } else if let passphrase = keychain.get(passphraseStoreKey), let keypair = core.createKeypairFor(passphrase: passphrase) {
                key = keypair
            } else {
                key = nil
            }
            
            let id = transaction.senderId
            if let key = key {
                checkName(of: id, for: recipient, api: api, core: core, keypair: key)
            }
            
            senderName = nil
        } else {
            senderName = nil
        }
        
        // MARK: 3. Setting UI
        
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
    private func showError(with message: String? = nil) {
        guard let warningView = UINib(nibName: "Warning", bundle: nil).instantiate(withOwner: nil, options: nil).first as? WarningView else {
            return
        }
        
        if let message = message {
            warningView.messageLabel.text = String.adamantLocalized.notifications.error(with: message)
        } else {
            warningView.messageLabel.text = String.adamantLocalized.notifications.error
        }
        
        view.addSubview(warningView)
        view.constrainToEdges(warningView)
    }
    
    private func checkName(of sender: String, for recipient: String, api: ExtensionsApi, core: NativeAdamantCore, keypair: Keypair) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let addressBook = api.getAddressBook(for: recipient, core: core, keypair: keypair), let name = addressBook[sender]?.displayName else {
                return
            }
            
            DispatchQueue.main.async {
                guard let vc = self else {
                    return
                }
                
                let address = self?.senderNameLabel.text
                
                UIView.transition(with: vc.senderAddressLabel,
                                  duration: 0.1,
                                  options: .transitionCrossDissolve,
                                  animations: { vc.senderAddressLabel.text = address },
                                  completion: nil)
                
                UIView.transition(with: vc.senderNameLabel,
                                  duration: 0.1,
                                  options: .transitionCrossDissolve,
                                  animations: { vc.senderNameLabel.text = name },
                                  completion: nil)
            }
        }
    }
}
