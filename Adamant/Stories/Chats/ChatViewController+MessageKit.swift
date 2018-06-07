//
//  ChatViewController+MessageKit.swift
//  Adamant
//
//  Created by Anokhov Pavel on 24.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import SafariServices
import Haring

// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
	func currentSender() -> Sender {
		guard let account = account else {
			fatalError("No account")
		}
		return Sender(id: account.address, displayName: account.address)
	}
	
	func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
		guard let message = chatController?.object(at: IndexPath(row: indexPath.section, section: 0)) as? MessageType else {
			// TODO: something
			fatalError("What?")
		}
		
		return message
	}
	
	func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
		if let objects = chatController?.fetchedObjects {
			return objects.count
		} else {
			return 0
		}
	}
	
	func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
		if message.sentDate == Date.adamantNullDate {
			return nil
		}
        
        if let message = message as? MessageTransaction, message.messageStatus == .pending || message.statusEnum == .fail {
            return nil
        }
		
		return NSAttributedString(string: dateFormatter.string(from: message.sentDate), attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
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
            guard let message = message as? MessageTransaction else {
                return UIColor.adamantChatSenderBackground
            }
            
            switch message.messageStatus {
            case .fail:
                return UIColor.adamantFailChatBackground
            default:
                return UIColor.adamantChatSenderBackground
            }
		} else {
			return UIColor.adamantChatRecipientBackground
		}
	}
	
	func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
		return UIColor.darkText
	}
	
	func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
		return [.url]
	}
    
    func configureAccessoryView(_ accessoryView: UIView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? MessageTransaction else {
            accessoryView.subviews.first?.removeFromSuperview()
            return
        }
        
        switch message.messageStatus {
        case .fail:
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
}

extension ChatViewController: MessageCellDelegate {
	func didTapMessage(in cell: MessageCollectionViewCell) {
		guard let indexPath = messagesCollectionView.indexPath(for: cell),
			let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
			return
		}
        
        if let message = message as? MessageTransaction, message.messageStatus == .fail {
            dialogService.showSystemActionSheet(title: String.adamantLocalized.alert.retryOrDeleteTitle, message: String.adamantLocalized.alert.retryOrDeleteBody, actions: [
                UIAlertAction(title: String.adamantLocalized.alert.retry, style: .default, handler: { action in
                    guard let partner = self.chatroom?.partner?.address else {
                        // TODO show warning
                        return
                    }
                    
                    self.chatsProvider.reSendMessage(message, recipientId: partner, completion: { result in
                        switch result {
                        case .success: break
                            
                        case .failure(let error):
                            let message: String
                            switch error {
                            case .accountNotFound(let account):
                                message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, "Account not found: \(account)")
                            case .dependencyError(let error):
                                message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, error)
                            case .internalError(let error):
                                message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, error.localizedDescription)
                            case .notLogged:
                                message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, "User not logged")
                            case .serverError(let error):
                                message = String.localizedStringWithFormat(String.adamantLocalized.chat.serverErrorFormat, error.localizedDescription)
                                
                            case .networkError:
                                message = String.adamantLocalized.chat.noNetwork
                                
                            case .notEnoughtMoneyToSend:
                                message = String.adamantLocalized.chat.notEnoughMoney
                                
                            case .messageNotValid(let problem):
                                switch problem {
                                case .tooLong:
                                    message = String.adamantLocalized.chat.messageTooLong
                                    
                                case .empty:
                                    message = String.adamantLocalized.chat.messageIsEmpty
                                    
                                case .isValid:
                                    message = ""
                                }
                            }
                            
                            // TODO: Log this
                            self.dialogService.showError(withMessage: message, error: error)
                        }
                        DispatchQueue.main.async {
                            print("reload data")
                            self.messagesCollectionView.reloadDataAndKeepOffset()
                        }
                    })
                }),
                UIAlertAction(title: String.adamantLocalized.alert.delete, style: .default, handler: { action in
                    self.chatsProvider.deleteLocalMessage(message, completion: { result in
                        switch result {
                        case .success: break
                            
                        case .failure(let error):
                            let message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, error.localizedDescription)
                            
                            self.dialogService.showError(withMessage: message, error: error)
                        }
                        DispatchQueue.main.async {
                            print("reload data")
                            self.messagesCollectionView.reloadDataAndKeepOffset()
                        }
                    })
                })])
            return
        }
		
		guard let transfer = message as? TransferTransaction else {
			return
		}
		
		guard let vc = router.get(scene: AdamantScene.Transactions.transactionDetails) as? TransactionDetailsViewController else {
			print("Can't get TransactionDetailsViewController")
			return
		}
		
		vc.transaction = transfer
		
		if let nav = navigationController {
			nav.pushViewController(vc, animated: true)
		} else {
			present(vc, animated: true, completion: nil)
		}
	}
	
	func didSelectURL(_ url: URL) {
		let safari = SFSafariViewController(url: url)
		safari.preferredControlTintColor = UIColor.adamantPrimary
		present(safari, animated: true, completion: nil)
	}
}


// MARK: - MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
	func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
		return 50
	}
	
	func avatarSize(for: MessageType, at: IndexPath, in: MessagesCollectionView) -> CGSize {
		return .zero
	}
	
	func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
		if isFromCurrentSender(message: message) {
			return LabelAlignment.messageTrailing(UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 16))
		} else {
			return LabelAlignment.messageLeading(UIEdgeInsets(top: 2, left: 16, bottom: 0, right: 0))
		}
	}
}


// MARK: - MessageInputBarDelegate
extension ChatViewController: MessageInputBarDelegate {
	func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
		let message = AdamantMessage.text(text)
		switch chatsProvider.validateMessage(message) {
		case .isValid:
			break
			
		case .empty:
			return
			
		case .tooLong:
			dialogService.showToastMessage(String.adamantLocalized.chat.messageTooLong)
			return
		}
		
		guard text.count > 0, let partner = chatroom?.partner?.address else {
			// TODO show warning
			return
		}
		
		self.chatsProvider.sendMessage(.text(text), recipientId: partner, completion: { result in
			switch result {
			case .success: break
				
			case .failure(let error):
				let message: String
				switch error {
				case .accountNotFound(let account):
					message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, "Account not found: \(account)")
				case .dependencyError(let error):
					message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, error)
				case .internalError(let error):
					message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, error.localizedDescription)
				case .notLogged:
					message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, "User not logged")
				case .serverError(let error):
					message = String.localizedStringWithFormat(String.adamantLocalized.chat.serverErrorFormat, error.localizedDescription)
					
				case .networkError:
					message = String.adamantLocalized.chat.noNetwork
					
				case .notEnoughtMoneyToSend:
					message = String.adamantLocalized.chat.notEnoughMoney
					
				case .messageNotValid(let problem):
					switch problem {
					case .tooLong:
						message = String.adamantLocalized.chat.messageTooLong
						
					case .empty:
						message = String.adamantLocalized.chat.messageIsEmpty
						
					case .isValid:
						message = ""
					}
				}
				
				// TODO: Log this
				self.dialogService.showError(withMessage: message, error: error)
			}
            DispatchQueue.main.async {
                
                print("reload data")
                self.messagesCollectionView.reloadDataAndKeepOffset()
                
            }
            
		})
		
		inputBar.inputTextView.text = String()
	}
	
	func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
		if text.count > 0 {
			let fee = AdamantMessage.text(text).fee
			setEstimatedFee(fee)
		} else {
			setEstimatedFee(0)
		}
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
		return self.transactionId!
	}
	
	public var sentDate: Date {
		return self.date! as Date
	}
	
	public var data: MessageData {
		guard let message = message else {
			return MessageData.text("")
		}
		
		if isMarkdown {
			let parser = MarkdownParser(font: UIFont.adamantChatDefault)
			return MessageData.attributedText(parser.parse(message))
		} else {
			return MessageData.text(message)
		}
	}
    
    public var messageStatus: MessageStatus {
        return self.statusEnum
    }
}

// MARK: TransferTransaction
extension TransferTransaction: MessageType {
	public var sender: Sender {
		let id = self.senderId!
		return Sender(id: id, displayName: id)
	}
	
	public var messageId: String {
		return transactionId!
	}
	
	public var sentDate: Date {
		return date! as Date
	}
	
	public var data: MessageData {
		return MessageData.attributedText(AdamantFormattingTools.formatTransferTransaction(self))
	}
}
