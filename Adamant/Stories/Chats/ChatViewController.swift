//
//  ChatViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 15.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import MessageKit
import CoreData

// MARK: - Localization
extension String.adamantLocalized {
	struct chat {
		static let estimatedFeeFormat = NSLocalizedString("Estimated fee: %f", comment: "Chat: input bar: Estimated fee.")
		
		static let messageIsEmpty = NSLocalizedString("Message is empty", comment: "Chat: Notify user that message cannot be empty")
		static let messageTooLong = NSLocalizedString("Message is too long", comment: "Chat: Message is too long")
		static let notEnoughMoney = NSLocalizedString("You don't have enough money to send a message", comment: "Chat: Notify user that he doesn't have money to pay a message fee")
		
		static let internalErrorFormat = NSLocalizedString("Internal error: %@. You should report this bug.", comment: "Chat: Notify user about bad internal error. Usually this should be reported as a bug.")
		static let serverErrorFormat = NSLocalizedString("Remote server error: %@", comment: "Chat: Notify user about server error.")
		
		private init() { }
	}
}


// MARK: - Delegate
protocol ChatViewControllerDelegate: class {
	func preserveMessage(_ message: String, forAddress address: String)
	func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String?
}


// MARK: -
class ChatViewController: MessagesViewController {
	// MARK: - Dependencies
	var chatsProvider: ChatsProvider!
	var dialogService: DialogService!
	var feeCalculator: FeeCalculator!
	
	// MARK: - Properties
	weak var delegate: ChatViewControllerDelegate?
	var account: Account?
	var chatroom: Chatroom?
	var dateFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}
	
	private(set) var chatController: NSFetchedResultsController<ChatTransaction>?
	private var controllerChanges: [NSFetchedResultsChangeType:[(indexPath: IndexPath?, newIndexPath: IndexPath?)]] = [:]
	
	// MARK: Fee label
	private var feeIsVisible: Bool = false
	private var feeTimer: Timer?
	private var feeLabel: InputBarButtonItem?
	private var prevFee: UInt = 0
	
	
	// MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		guard let chatroom = chatroom else {
			print("Failed to get chat controller")
			return
		}
		
		// MARK: 1. Initial configuration
		
		if let partner = chatroom.partner {
			if let name = partner.name {
				self.navigationItem.title = name
			} else {
				self.navigationItem.title = partner.address
			}
		}
		
		messagesCollectionView.messagesDataSource = self
		messagesCollectionView.messagesDisplayDelegate = self
		messagesCollectionView.messagesLayoutDelegate = self
		maintainPositionOnKeyboardFrameChanged = true
		
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			guard let controller = self?.chatsProvider.getChatController(for: chatroom) else {
				return
			}

			controller.delegate = self
			self?.chatController = controller

			if let collection = self?.messagesCollectionView {
				DispatchQueue.main.async {
					collection.reloadData()
					collection.scrollToBottom(animated: true)
				}
			}
		}
		
		
		// MARK: 2. InputBar configuration
		
		messageInputBar.delegate = self
		
		let bordersColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
		let size: CGFloat = 6.0
		
		messageInputBar.separatorLine.backgroundColor = bordersColor
		messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
		messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: size, left: size*2, bottom: size, right: size*2)
		messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: size, left: size*2+4, bottom: size, right: size*2+4)
		messageInputBar.inputTextView.layer.borderColor = bordersColor.cgColor
		messageInputBar.inputTextView.layer.borderWidth = 1.0
		messageInputBar.inputTextView.layer.cornerRadius = size*2
		messageInputBar.inputTextView.layer.masksToBounds = true
		messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
		
		messageInputBar.setStackViewItems([], forStack: .right, animated: false)
		messageInputBar.setRightStackViewWidthConstant(to: 0, animated: false)
		
		let feeLabel = InputBarButtonItem()
		self.feeLabel = feeLabel
		feeLabel.isEnabled = false
		feeLabel.titleLabel?.font = UIFont.adamantPrimary(size: 12)
		feeLabel.alpha = 0
		feeLabel.isHidden = true
		
		messageInputBar.setStackViewItems([feeLabel, .flexibleSpace, messageInputBar.sendButton], forStack: .bottom, animated: false)
		messageInputBar.sendButton.configure {
			$0.setTitleColor(UIColor.adamantPrimary, for: .normal)
			$0.setTitleColor(UIColor.adamantSecondary, for: .highlighted)
		}
		
		if let delegate = delegate, let address = chatroom.partner?.address, let message = delegate.getPreservedMessageFor(address: address, thenRemoveIt: true) {
			messageInputBar.inputTextView.text = message
			setEstimatedFee(feeCalculator.estimatedFeeFor(message: AdamantMessage.text(message)))
		}
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if let delegate = delegate, let message = messageInputBar.inputTextView.text, let address = chatroom?.partner?.address {
			delegate.preserveMessage(message, forAddress: address)
		}
	}
	
	@IBAction func properties(_ sender: Any) {
		if let address = chatroom?.partner?.address {
			dialogService.presentShareAlertFor(string: address, types: [.copyToPasteboard, .share], animated: true, completion: nil)
		}
	}
}



// MARK: - EstimatedFee label
extension ChatViewController {
	private func setEstimatedFee(_ fee: UInt) {
		if prevFee != fee && fee > 0 {
			guard let feeLabel = feeLabel else {
				return
			}
			
			let text = String.localizedStringWithFormat(String.adamantLocalized.chat.estimatedFeeFormat, AdamantUtilities.from(uInt: fee))
			prevFee = fee
			
			feeLabel.title = text
			feeLabel.setSize(CGSize(width: feeLabel.titleLabel!.intrinsicContentSize.width, height: 20), animated: false)
		}
		
		if !feeIsVisible && fee > 0 {
			feeIsVisible = true
			feeTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
				DispatchQueue.main.async {
					self?.feeLabel?.isHidden = false
					UIView.animate(withDuration: 0.3, animations: {
						self?.feeLabel?.alpha = 1
					})
					
					self?.feeTimer = nil
				}
			}
		} else if feeIsVisible && fee <= 0 {
			feeIsVisible = false
			
			if let feeTimer = feeTimer, feeTimer.isValid {
				feeTimer.invalidate()
			}
			
			UIView.animate(withDuration: 0.3, animations: {
				self.feeLabel?.alpha = 0
			}, completion: { _ in
				self.feeLabel?.isHidden = true
			})
			
			feeTimer = nil
		}
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension ChatViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		controllerChanges.removeAll()
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		performBatchChanges(controllerChanges)
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		if controllerChanges[type] == nil {
			controllerChanges[type] = [(IndexPath?, IndexPath?)]()
		}
		controllerChanges[type]!.append((indexPath, newIndexPath))
	}
	
	private func performBatchChanges(_ changes: [NSFetchedResultsChangeType:[(indexPath: IndexPath?, newIndexPath: IndexPath?)]]) {
		for (type, change) in changes {
			switch type {
			case .insert:
				let sections = IndexSet(change.flatMap({$0.newIndexPath?.row}))
				if sections.count > 0 {
					messagesCollectionView.insertSections(sections)
					messagesCollectionView.scrollToBottom(animated: true)
				}
				
			case .delete:
				let sections = IndexSet(change.flatMap({$0.indexPath?.row}))
				if sections.count > 0 {
					messagesCollectionView.deleteSections(sections)
				}
				
			case .move:
				for paths in change {
					if let section = paths.indexPath?.row, let newSection = paths.newIndexPath?.row {
						messagesCollectionView.moveSection(section, toSection: newSection)
					}
				}
				
			case .update:
				// TODO: update
				return
			}
		}
	}
}


// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
	func currentSender() -> Sender {
		guard let account = account else {
			fatalError("No account")
		}
		return Sender(id: account.address, displayName: account.address)
	}
	
	func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
		guard let message = chatController?.object(at: IndexPath(row: indexPath.section, section: 0)) else {
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
}


// MARK: - MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
	func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
		let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
		return .bubbleTail(corner, .curved)
	}
	
	func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
		if isFromCurrentSender(message: message) {
			return UIColor.adamantChatSenderBackground
		} else {
			return UIColor.adamantChatRecipientBackground
		}
	}
	
	func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
		return UIColor.darkText
	}
	
	func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
		return []
	}
	
	func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
		return NSAttributedString(string: dateFormatter.string(from: message.sentDate), attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)])
	}
	
	func cellBottomLabelAlignment(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LabelAlignment {
		if isFromCurrentSender(message: message) {
			return LabelAlignment.messageTrailing(UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 16))
		} else {
			return LabelAlignment.messageLeading(UIEdgeInsets(top: 2, left: 16, bottom: 0, right: 0))
		}
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
		
		DispatchQueue.global(qos: .userInitiated).async {
			self.chatsProvider.sendMessage(.text(text), recipientId: partner, completion: { result in
				switch result {
				case .success: break
					
				case .error(let error):
					let message: String
					switch error {
					case .accountNotFound(let account):
						message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, "Account not found: \(account)")
					case .dependencyError(let error):
						message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, error)
					case .internalError(let error):
						message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, String(describing: error))
					case .notLogged:
						message = String.localizedStringWithFormat(String.adamantLocalized.chat.internalErrorFormat, "User not logged")
					case .serverError(let error):
						message = String.localizedStringWithFormat(String.adamantLocalized.chat.serverErrorFormat, String(describing: error))

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
					self.dialogService.showToastMessage(message)
				}
				
			})
		}
		inputBar.inputTextView.text = String()
	}
	
	func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
		if text.count > 0 {
			let fee = feeCalculator.estimatedFeeFor(message: .text(text))
			setEstimatedFee(fee)
		} else {
			setEstimatedFee(0)
		}
	}
}


// MARK: - ChatTransaction: MessageType
extension ChatTransaction: MessageType {
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
		return MessageData.text(self.message ?? "")
	}
}
