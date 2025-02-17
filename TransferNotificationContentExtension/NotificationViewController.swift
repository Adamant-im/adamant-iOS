//
//  NotificationViewController.swift
//  TransferNotificationContentExtension
//
//  Created by Anokhov Pavel on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import UserNotifications
import UserNotificationsUI
import MarkdownKit
import CommonKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private let passphraseStoreKey = "accountService.passphrase"
    private let sizeWithoutCommentLabel: CGFloat = 350.0
    
    // MARK: - Rich providers
    private lazy var adamantProvider: AdamantProvider = {
        return AdamantProvider()
    }()
    
    private lazy var keychain: SecuredStore = {
        KeychainStore(secureStorage: AdamantSecureStorage())
    }()
    
    /// Lazy contstructors
    private lazy var richMessageProviders: [String: TransferNotificationContentProvider] = {
        var providers: [String: TransferNotificationContentProvider] = [
            EthProvider.richMessageType: EthProvider(),
            KlyProvider.richMessageType: KlyProvider(),
            DogeProvider.richMessageType: DogeProvider(),
            DashProvider.richMessageType: DashProvider(),
            BtcProvider.richMessageType: BtcProvider()
        ]
        
        for token in ERC20Token.supportedTokens {
            let key = "\(token.symbol)_transaction".lowercased()
            providers[key] = ERC20Provider(token)
        }
        
        return providers
    }()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var senderAddressLabel: UILabel!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBOutlet weak var senderImageView: UIImageView!
    
    @IBOutlet weak var recipientAddressLabel: UILabel!
    @IBOutlet weak var recipientNameLabel: UILabel!
    @IBOutlet weak var recipientImageView: UIImageView!
    
    @IBOutlet weak var outcomeArrowImageView: UIImageView!
    @IBOutlet weak var outcomeArrowView: UIView!
    @IBOutlet weak var incomeArrowImageView: UIImageView!
    @IBOutlet weak var incomeArrowView: UIView!
    
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var currencySymbolLabel: UILabel!
    @IBOutlet weak var currencyImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        incomeArrowView.layer.cornerRadius = incomeArrowView.frame.height/2
        incomeArrowView.isHidden = true
        
        outcomeArrowView.layer.cornerRadius = outcomeArrowView.frame.height/2
        outcomeArrowView.isHidden = true
        
        senderAddressLabel.text = ""
        senderNameLabel.text = ""
        recipientAddressLabel.text = ""
        recipientNameLabel.text = ""
        amountLabel.text = ""
        currencySymbolLabel.text = ""
        dateLabel.text = ""
        commentLabel.text = ""
        
        setColors()
    }
    
    private func setColors() {
        let color = UIColor.adamant.textColor.resolvedColor(with: .current)
        senderAddressLabel.textColor = color
        senderNameLabel.textColor = color
        recipientAddressLabel.textColor = color
        recipientNameLabel.textColor = color
        amountLabel.textColor = color
        currencySymbolLabel.textColor = color
        dateLabel.textColor = color
        commentLabel.textColor = color
        
        senderImageView.tintColor = UIColor.adamant.primary
        recipientImageView.tintColor = UIColor.adamant.primary
        currencyImageView.tintColor = UIColor.adamant.primary
        
        incomeArrowImageView.tintColor = UIColor.white
        outcomeArrowImageView.tintColor = UIColor.white
        
        incomeArrowView.backgroundColor = UIColor.adamant.incomeArrowBackgroundColor
        createBorder(for: incomeArrowView, width: 2.5, color: UIColor.white)
        
        outcomeArrowView.backgroundColor = UIColor.adamant.outcomeArrowBackgroundColor
        createBorder(for: outcomeArrowView, width: 2.5, color: UIColor.white)
    }
    
    private func createBorder(for view: UIView, width: CGFloat, color: UIColor) {
        let border = CAShapeLayer()
        border.frame = view.bounds
        border.lineWidth = width
        border.path = UIBezierPath(ovalIn: border.bounds).cgPath
        border.strokeColor = UIColor.white.cgColor
        border.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(border)
    }
    
    func didReceive(_ notification: UNNotification) {
        // MARK: 0. Services
        let core = NativeAdamantCore()
        let avatarService = AdamantAvatarService()
        let api = ExtensionsApiFactory(core: core, securedStore: keychain).make()
        
        guard let passphrase: String = keychain.get(passphraseStoreKey),
              let keypair = core.createKeypairFor(passphrase: passphrase, password: .empty)
        else {
            showError()
            return
        }
        
        // MARK: 1. Get the transaction
        let trs: Transaction?
        if let transactionRaw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transaction] as? String, let data = transactionRaw.data(using: .utf8) {
            trs = try? JSONDecoder().decode(Transaction.self, from: data)
        } else {
            guard let raw = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.transactionId] as? String, let id = UInt64(raw) else {
                showError()
                return
            }
            
            trs = api.getTransaction(by: id)
        }
        
        guard let transaction = trs else {
            showError()
            return
        }
        
        // MARK: 2.1 Variables for UI
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
                    let richContent = RichMessageTools.richContent(from: data),
                      let key = (richContent[RichContentKeys.type] as? String)?.lowercased(),
                    let p = richMessageProviders[key] else {
                        showError()
                        return
                }
                
                provider = p
                
                if let raw = richContent[RichContentKeys.transfer.comments] as? String,
                   raw.count > 0 {
                    comments = raw
                } else {
                    comments = nil
                }
                
                if let raw = richContent[RichContentKeys.transfer.amount] as? String,
                   let decimal = Decimal(string: raw) {
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
        
        // MARK: 3. Names
        let senderName: String?
        
        // Cached
        if let name = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.partnerDisplayName] as? String {
            senderName = name
        }
        // No name, but we have flag - skip it
        else if let flag = notification.request.content.userInfo[AdamantNotificationUserInfoKeys.partnerNoDislpayNameKey] as? String, flag == AdamantNotificationUserInfoKeys.partnerNoDisplayNameValue {
            senderName = nil
        } else {
            checkName(of: transaction.senderId, for: transaction.recipientId, api: api, core: core, keypair: keypair)
            senderName = nil
        }
        
        // MARK: 3. Setting up UI
        
        if let name = senderName {
            senderNameLabel.text = name
            senderAddressLabel.text = transaction.senderId
        } else {
            senderNameLabel.text = transaction.senderId
            senderAddressLabel.text = nil
        }
        
        recipientNameLabel.text = String.adamant.notifications.yourAddress
        recipientAddressLabel.text = transaction.recipientId
        
        dateLabel.text = date.humanizedDateTime()

        currencyImageView.image = provider.currencyLogoLarge
        amountLabel.text = AdamantBalanceFormat.full.format(amount)
        currencySymbolLabel.text = provider.currencySymbol
        
        if let comments = comments {
            let parsed = MarkdownParser(font: commentLabel.font).parse(comments)
            
            if parsed.string.count != comments.count {
                commentLabel.attributedText = parsed
            } else {
                commentLabel.text = comments
            }
        } else {
            commentLabel.isHidden = true
        }
        
        let size = Double(senderImageView.frame.height)
        senderImageView.image = avatarService.avatar(for: transaction.senderPublicKey, size: size)
        recipientImageView.image = avatarService.avatar(for: keypair.publicKey, size: size)
        
        // MARK: 4. View size
        if comments != nil {
            commentLabel.setNeedsLayout()
            commentLabel.layoutIfNeeded()
            preferredContentSize = CGSize(width: view.frame.width, height: sizeWithoutCommentLabel + commentLabel.frame.height)
        } else {
            commentLabel.isHidden = true
            preferredContentSize = CGSize(width: view.frame.width, height: sizeWithoutCommentLabel)
        }
        
        incomeArrowView.isHidden = false
        outcomeArrowView.isHidden = false
        
        view.setNeedsUpdateConstraints()
        view.setNeedsLayout()
    }
    
    // MARK: - UI
    private func showError(with message: String? = nil) {
        let warningView = NotificationWarningView()
        
        warningView.message = message.map { .adamant.notifications.error(with: $0) }
            ?? .adamant.notifications.error
        
        view.addSubview(warningView)
        warningView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
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
