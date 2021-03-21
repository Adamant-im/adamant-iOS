//
//  ChatViewController+MessageKit.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import MessageInputBar
import SafariServices
import MarkdownKit


// MARK: - Tools
extension ChatViewController {
    private func getRichMessageType(of message: MessageType) -> String? {
        guard case .custom(let raw) = message.kind, let transfer = raw as? RichMessageTransfer else {
            return nil
        }
        
        return transfer.type
    }
}


// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    func currentSender() -> Sender {
        guard let account = account else {
            // Until we will update our network to procedures
            return(Sender(id: "your moma", displayName: ""))
//            fatalError("No account")
        }
        return Sender(id: account.address, displayName: account.address)
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        guard let message = chatController?.object(at: IndexPath(row: indexPath.section, section: 0)) as? MessageType else {
            fatalError("Data not synced")
        }
        
        return message
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        if let objects = chatController?.fetchedObjects {
            return objects.count
        } else {
            return 0
        }
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if self.shouldDisplayHeader(for: message, at: indexPath, in: self.messagesCollectionView) {
            return NSAttributedString(string: message.sentDate.humanizedDay(), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.adamant.secondary])
        }
        return nil
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isFromCurrentSender(message: message) {
            guard let transaction = message as? ChatTransaction else {
                return nil
            }
            
            switch transaction.statusEnum {
            case .failed:
                return NSAttributedString(string: String.adamantLocalized.chat.failToSend, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.adamant.primary])
                
            case .pending:
                return NSAttributedString(string: String.adamantLocalized.chat.pending, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.adamant.primary])
                
            case .delivered:
                return nil
            }
        } else {
            return nil
        }
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if message.sentDate == Date.adamantNullDate {
            return nil
        }
        
        if let message = message as? MessageTransaction, message.statusEnum == .failed {
            return nil
        }
        
        let humanizedTime = message.sentDate.humanizedTime()
        
        if let expire = humanizedTime.expireIn {
            if !cellsUpdating.contains(indexPath) {
                cellsUpdating.append(indexPath)
                
                let timer = Timer.scheduledTimer(withTimeInterval: expire + 1, repeats: false) { [weak self] timer in
                    self?.messagesCollectionView.reloadItems(at: [indexPath])
                    
                    if let index = self?.cellsUpdating.firstIndex(of: indexPath) {
                        self?.cellsUpdating.remove(at: index)
                    }
                    
                    if let index = self?.cellUpdateTimers.firstIndex(of: timer) {
                        self?.cellUpdateTimers.remove(at: index)
                    }
                }
                
                cellUpdateTimers.append(timer)
            }
        }
        
        return NSAttributedString(string: humanizedTime.string, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2), NSAttributedString.Key.foregroundColor: UIColor.adamant.secondary])
    }
    
    func customCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell {
        guard let type = getRichMessageType(of: message), let provider = richMessageProviders[type] else {
            fatalError("Tried to render wrong messagetype: \(message.kind)")
        }
        
        let fromCurrent = isFromCurrentSender(message: message)
        
        let cell = provider.cell(for: message, isFromCurrentSender: fromCurrent, at: indexPath, in: messagesCollectionView)
        
        if let chatCell = cell as? ChatCell {
//            let corner: MessageStyle.TailCorner = fromCurrent ? .bottomRight : .bottomLeft
//            chatCell.bubbleStyle = .bubbleTail(corner, .curved)
            
            let bgColor: UIColor
            if fromCurrent {
                if let transaction = message as? ChatTransaction {
                    switch transaction.statusEnum {
                    case .failed: bgColor = UIColor.adamant.failChatBackground
                    case .pending: bgColor = UIColor.adamant.pendingChatBackground
                    case .delivered: bgColor = UIColor.adamant.chatSenderBackground
                    }
                } else {
                    bgColor = UIColor.adamant.chatSenderBackground
                }
            } else {
                bgColor = UIColor.adamant.chatRecipientBackground
            }
            
            chatCell.bubbleBackgroundColor = bgColor
        }
        
        if let transferCell = cell as? TransferCollectionViewCell, let calculator = cellCalculators[type] as? TransferMessageSizeCalculator {
            let width = calculator.messageContainerMaxWidth(for: message) - TransferCollectionViewCell.statusImageSizeAndSpace
            transferCell.transferContentWidthConstraint.constant = width
        }
        
        // MARK: Delegates
        switch cell {
        case let tapCell as TapRecognizerCustomCell:
            tapCell.delegate = self
            
        case let transferCell as TapRecognizerTransferCell:
            transferCell.delegate = self
            
        default:
            break
        }
        
        // MARK: Rich transfer statuses
        if let richTransaction = message as? RichMessageTransaction {
            switch richTransaction.transactionStatus {
            case nil, .notInitiated?:
                guard let updater = provider as? RichMessageProviderWithStatusCheck else {
                    break
                }
                
                /*
                 Сообщения-отчёты об отправленных средствах создаются раньше, чем на эфирных нодах появляется сама транзакция перевода (по ТЗ).
                 Проблема - как только сообщение появляется в чате, мы запрашиваем у эфирной ноды статус транзакции которую ещё не отправили - нода возвращает ошибку.
                 Решение - если сообщение появилось только что - обновим статус этой транзакции с 'некоторой' задержкой.
                 🤷🏻‍♂️
                 */
                if let date = richTransaction.date, date.timeIntervalSinceNow > -2.0 {
                    updateStatus(for: richTransaction, provider: updater, delay: 5.0)
                } else {
                    updateStatus(for: richTransaction, provider: updater)
                }
                
            case .pending?:
                guard !isUpdatingRichMessageStatus(id: richTransaction.objectID), let updater = provider as? RichMessageProviderWithStatusCheck else {
                    break
                }
                
                updateStatus(for: richTransaction, provider: updater)
                
            default:
                break
            }
        }
        
        return cell
    }
}


// MARK: - MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            guard let transaction = message as? ChatTransaction else {
                return UIColor.adamant.chatSenderBackground
            }
            
            switch transaction.statusEnum {
            case .failed:
                return UIColor.adamant.failChatBackground
                
            case .pending:
                return UIColor.adamant.pendingChatBackground
                
            case .delivered:
                return UIColor.adamant.chatSenderBackground
            }
        } else {
            return UIColor.adamant.chatRecipientBackground
        }
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return UIColor.adamant.primary
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url]
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        if detector == .url {
            return [NSAttributedString.Key.foregroundColor:UIColor.adamant.active]
        }
        return [:]
    }
    
    func configureAccessoryView(_ accessoryView: UIView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? MessageTransaction else {
            accessoryView.subviews.first?.removeFromSuperview()
            return
        }
        
        switch message.messageStatus {
        case .failed:
            let icon = UIImageView(frame: CGRect(x: -28, y: -10, width: 20, height: 20))
            icon.contentMode = .scaleAspectFit
            icon.backgroundColor = UIColor.clear
            icon.image = #imageLiteral(resourceName: "cross")
            accessoryView.addSubview(icon)
            return
        default:
            accessoryView.subviews.first?.removeFromSuperview()
            return
        }
    }
    
    func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
        if message.sentDate == Date.adamantNullDate {
            return false
        }
        
        guard let dataSource = messagesCollectionView.messagesDataSource else {
            return false
        }
        
        if indexPath.section == 0 {
            return true
        }
        
        let previousSection = indexPath.section - 1
        let previousIndexPath = IndexPath(item: 0, section: previousSection)
        let previousMessage = dataSource.messageForItem(at: previousIndexPath, in: messagesCollectionView)
        let timeIntervalSinceLastMessage = message.sentDate.timeIntervalSince(previousMessage.sentDate)
        return timeIntervalSinceLastMessage >= self.showsDateHeaderAfterTimeInterval
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
            return
        }
        
        switch message {
        // MARK: Show Retry/Cancel action sheet
        case let message as MessageTransaction:
            // Only for failed messages
            guard message.messageStatus == .failed else {
                break
            }
            
            let retry = UIAlertAction(title: String.adamantLocalized.alert.retry, style: .default, handler: { [weak self] action in
                self?.chatsProvider.retrySendMessage(message) { result in
                    switch result {
                    case .success: break
                        
                    case .failure(let error):
                        self?.dialogService.showRichError(error: error)
                        
                    case .invalidTransactionStatus(_):
                        break
                    }
                }
            })
            
            let cancelMessage = UIAlertAction(title: String.adamantLocalized.alert.delete, style: .default, handler: { [weak self] action in
                self?.chatsProvider.cancelMessage(message) { result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            self?.messagesCollectionView.reloadDataAndKeepOffset()
                        }
                        
                    case .invalidTransactionStatus(_):
                        self?.dialogService.showWarning(withMessage: String.adamantLocalized.chat.cancelError)
                        
                    case .failure(let error):
                        self?.dialogService.showRichError(error: error)
                    }
                }
            })
            
            let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel)
            
            dialogService?.showAlert(title: String.adamantLocalized.alert.retryOrDeleteTitle, message: String.adamantLocalized.alert.retryOrDeleteBody, style: .actionSheet, actions: [retry, cancelMessage, cancel], from: cell)
            
            
        // MARK: Show ADM transfer details
        case let transfer as TransferTransaction:
            guard let provider = richMessageProviders[AdmWalletService.richMessageType] as? AdmWalletService else {
                return
            }
            
            provider.richMessageTapped(for: transfer, at: indexPath, in: self)
            
        // MARK: Pass event to rich message provider
        case let richMessage as RichMessageTransaction:
            guard let type = richMessage.richType, let provider = richMessageProviders[type] else {
                break
            }
            
            if richMessage.transactionStatus == .dublicate {
                dialogService.showAlert(title: nil, message: String.adamantLocalized.sharedErrors.duplicatedTransaction, style: AdamantAlertStyle.alert, actions: nil, from: nil)
            } else  if richMessage.transactionStatus == .failed {
                dialogService.showAlert(title: nil, message: String.adamantLocalized.sharedErrors.inconsistentTransaction, style: AdamantAlertStyle.alert, actions: nil, from: nil)
            } else {
                provider.richMessageTapped(for: richMessage, at: indexPath, in: self)
            }
            
            
        default:
            break
        }
    }
    
    func didSelectURL(_ url: URL) {
        if url.absoluteString.starts(with: "http") {
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            present(safari, animated: true, completion: nil)
        } else if url.absoluteString.starts(with: "mailto") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                dialogService.showWarning(withMessage: String.adamantLocalized.chat.noMailAppWarning)
            }
        } else {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                dialogService.showWarning(withMessage:String.adamantLocalized.chat.unsupportedUrlWarning)
            }
        }
    }
}

// MARK: - TransferCollectionViewCellDelegate
extension ChatViewController: CustomCellDelegate {
    func didTapCustomCell(_ cell: TapRecognizerCustomCell) {
        guard let c = cell as? UICollectionViewCell,
            let indexPath = messagesCollectionView.indexPath(for: c),
            let transaction = chatController?.object(at: IndexPath(row: indexPath.section, section: 0)) else {
            return
        }
        
        switch transaction {
        case let transfer as TransferTransaction:
            guard let provider = richMessageProviders[AdmWalletService.richMessageType] as? AdmWalletService else {
                break
            }
            
            provider.richMessageTapped(for: transfer, at: indexPath, in: self)
            
        case let richTransaction as RichMessageTransaction:
            guard let type = richTransaction.richType, let provider = richMessageProviders[type] else {
                break
            }
            
            if richTransaction.transactionStatus == .dublicate {
                dialogService.showAlert(title: nil, message: String.adamantLocalized.sharedErrors.duplicatedTransaction, style: AdamantAlertStyle.alert, actions: nil, from: nil)
            } else if richTransaction.transactionStatus == .failed {
                dialogService.showAlert(title: nil, message: String.adamantLocalized.sharedErrors.inconsistentTransaction, style: AdamantAlertStyle.alert, actions: nil, from: nil)
            } else {
                provider.richMessageTapped(for: richTransaction, at: indexPath, in: self)
            }
            
        default:
            return
        }
    }
}

// MARK: - TransferCollectionViewCellDelegate
extension ChatViewController: TransferCellDelegate {
    func didTapTransferCell(_ cell: TapRecognizerTransferCell) {
        guard let c = cell as? UICollectionViewCell,
            let indexPath = messagesCollectionView.indexPath(for: c),
            let transaction = chatController?.object(at: IndexPath(row: indexPath.section, section: 0)) else {
                return
        }
        
        switch transaction {
        case let transfer as TransferTransaction:
            guard let provider = richMessageProviders[AdmWalletService.richMessageType] as? AdmWalletService else {
                break
            }
            
            provider.richMessageTapped(for: transfer, at: indexPath, in: self)
            
        case let richTransaction as RichMessageTransaction:
            guard let type = richTransaction.richType, let provider = richMessageProviders[type] else {
                break
            }
            
            if richTransaction.transactionStatus == .dublicate {
                dialogService.showAlert(title: nil, message: String.adamantLocalized.sharedErrors.duplicatedTransaction, style: AdamantAlertStyle.alert, actions: nil, from: nil)
            } else  if richTransaction.transactionStatus == .failed {
                dialogService.showAlert(title: nil, message: String.adamantLocalized.sharedErrors.inconsistentTransaction, style: AdamantAlertStyle.alert, actions: nil, from: nil)
            } else {
                provider.richMessageTapped(for: richTransaction, at: indexPath, in: self)
            }
            
        default:
            return
        }
    }
    
    func didTapTransferCellStatus(_ cell: TapRecognizerTransferCell) {
        guard let c = cell as? UICollectionViewCell,
            let indexPath = messagesCollectionView.indexPath(for: c),
            let transaction = chatController?.object(at: IndexPath(row: indexPath.section, section: 0)) as? RichMessageTransaction else {
                return
        }
        
        guard transaction.transactionStatus != TransactionStatus.updating else {
            return
        }
        
        guard let type = transaction.richType,
            let provider = richMessageProviders[type] as? RichMessageProviderWithStatusCheck else {
                return
        }
        
        updateStatus(for: transaction, provider: provider, delay: 1)
    }
}

// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if self.shouldDisplayHeader(for: message, at: indexPath, in: messagesCollectionView) {
            return 16
        }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if message is TransferTransaction {
            return 0
        }
        
        if isFromCurrentSender(message: message) {
            guard let transaction = message as? ChatTransaction else {
                return 0
            }
            
            switch transaction.statusEnum {
            case .failed, .pending:
                return 16
                
            case .delivered:
                return 0
            }
        } else {
            return 0
        }
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if message is TransferTransaction {
            return 16
        }
        
        if isFromCurrentSender(message: message) {
            guard let transaction = message as? ChatTransaction else {
                return 16
            }
            
            switch transaction.statusEnum {
            case .failed, .pending:
                return 0
                
            case .delivered:
                return 16
            }
        } else {
            return 16
        }
    }
    
    func customCellSizeCalculator(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CellSizeCalculator {
        guard let type = getRichMessageType(of: message) else {
            return (messagesCollectionView.collectionViewLayout as! MessagesCollectionViewFlowLayout).textMessageSizeCalculator
        }
        
        if let calculator = cellCalculators[type] {
            return calculator
        } else if let provider = richMessageProviders[type] {
            let calculator = provider.cellSizeCalculator(for: messagesCollectionView.collectionViewLayout as! MessagesCollectionViewFlowLayout)
            cellCalculators[type] = calculator
            return calculator
        } else {
            return (messagesCollectionView.collectionViewLayout as! MessagesCollectionViewFlowLayout).textMessageSizeCalculator
        }
    }
}


// MARK: - MessageInputBarDelegate
extension ChatViewController: MessageInputBarDelegate {
    private static let markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let parsedText = ChatViewController.markdownParser.parse(text)
        
        let message: AdamantMessage
        if parsedText.length == text.count {
            message = .text(text)
        } else {
            message = .markdownText(text)
        }
        
        let valid = chatsProvider.validateMessage(message)
        switch valid {
        case .isValid:
            break
            
        case .empty:
            return
            
        case .tooLong:
            dialogService.showToastMessage(valid.localized)
            return
        }
        
        guard text.count > 0, let partner = chatroom?.partner?.address else {
            // TODO show warning
            return
        }
        
        chatsProvider.sendMessage(message, recipientId: partner, from: chatroom, completion: { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.scrollDown()
                }
                break
                
            case .failure(let error):
                var showFreeToken = false
                switch error {
                case .messageNotValid:
                    self?.setText(text, to: inputBar)
                case .notEnoughMoneyToSend:
                    self?.setText(text, to: inputBar)
                    if let transfersProvider = self?.transfersProvider, !transfersProvider.hasTransactions {
                        showFreeToken = true
                    }
                default:
                    break
                }
                
                if showFreeToken {
                    self?.showFreeTokenAlert()
                } else {
                    self?.dialogService.showRichError(error: error)
                }
            }
        })
        
        inputBar.inputTextView.text = String()
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        if text.count > 0 {
            feeUpdateTimer?.invalidate()
            feeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
                print("update fee")
                DispatchQueue.background.async {
                    let fee = AdamantMessage.text(text).fee
                    DispatchQueue.main.async {
                        self.setEstimatedFee(fee)
                    }
                }
            })
        } else {
            setEstimatedFee(0)
        }
    }
    
    func setText(_ text: String, to inputBar: MessageInputBar) {
        DispatchQueue.main.async {
            if inputBar.inputTextView.text.count == 0 {
                inputBar.inputTextView.text = text
            }
        }
    }
    
    func showFreeTokenAlert() {
        let alert = UIAlertController(title: "", message: String.adamantLocalized.chat.freeTokensMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.adamantLocalized.chat.freeTokens, style: .default, handler: { [weak self] (_) in
            if let address = self?.account?.address {
                let urlRaw = String.adamantLocalized.wallets.getFreeTokensUrl(for: address)
                guard let url = URL(string: urlRaw) else {
                    self?.dialogService.showError(withMessage: "Failed to create URL with string: \(urlRaw)", error: nil)
                    return
                }
                
                let safari = SFSafariViewController(url: url)
                safari.preferredControlTintColor = UIColor.adamant.primary
                safari.modalPresentationStyle = .overFullScreen
                self?.present(safari, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .default, handler: nil))
        alert.modalPresentationStyle = .overFullScreen
        present(alert, animated: true, completion: nil)
    }
}


// MARK: - MessageType
// MARK: MessageTransaction
extension MessageTransaction: MessageType {
    public var sender: Sender {
        let id = self.senderId!
        return Sender(id: id, displayName: id)
    }
    
    public var messageId: String {
        return chatMessageId!
    }
    
    public var sentDate: Date {
        return date! as Date
    }
    
    public var kind: MessageKind {
        guard let message = message else {
            isHidden = true
            try? managedObjectContext?.save()
            return MessageKind.text("")
        }
        
        if isMarkdown {
            let markdown = MessageTransaction.markdownParser.parse(message)
            return MessageKind.attributedText(markdown)
        } else {
            return MessageKind.text(message)
        }
    }
    
    public var messageStatus: MessageStatus {
        return self.statusEnum
    }
    
    private static let markdownParser: MarkdownParser = {
        let parser = MarkdownParser(font: UIFont.adamantChatDefault,
                                    color: UIColor.adamant.primary)
        parser.link.color = UIColor.adamant.active
        parser.automaticLink.color = UIColor.adamant.active
        return parser
    }()
}

// MARK: RichMessageTransaction
extension RichMessageTransaction: MessageType {
    public var sender: Sender {
        let id = self.senderId!
        return Sender(id: id, displayName: id)
    }
    
    public var messageId: String {
        return chatMessageId!
    }
    
    public var sentDate: Date {
        return date! as Date
    }
}

// MARK: TransferTransaction
extension TransferTransaction: MessageType {
    public var sender: Sender {
        let id = self.senderId!
        return Sender(id: id, displayName: id)
    }
    
    public var messageId: String {
        return chatMessageId!
    }
    
    public var sentDate: Date {
        return date! as Date
    }
    
    public var kind: MessageKind {
        return MessageKind.custom(RichMessageTransfer(type: AdmWalletService.richMessageType,
                                                      amount: amount as Decimal? ?? 0,
                                                      hash: "",
                                                      comments: comment ?? ""))
    }
}
