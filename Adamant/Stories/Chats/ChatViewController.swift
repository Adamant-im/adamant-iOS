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
		static let sendButton = NSLocalizedString("ChatScene.Send", comment: "Chat: Send message button")
		static let messageInputPlaceholder = NSLocalizedString("ChatScene.NewMessage.Placeholder", comment: "Chat: message input placeholder")
		static let cancelError = NSLocalizedString("ChatScene.Error.cancelError", comment: "Chat: inform user that he can't cancel transaction, that was sent")
        static let failToSend = NSLocalizedString("ChatScene.MessageStatus.FailToSend", comment: "Chat: status message for failed to send chat transaction")
        static let pending = NSLocalizedString("ChatScene.MessageStatus.Pending", comment: "Chat: status message for pending chat transaction")
        
        static let actionsTitle = NSLocalizedString("ChatScene.Actions.Title", comment: "Chat: Title for actions menu")
        static let actionsBody = NSLocalizedString("ChatScene.Actions.Body", comment: "Chat: Body for actions menu")
        static let rename = NSLocalizedString("ChatScene.Actions.Rename", comment: "Chat: 'Rename' action in actions menu")
        static let name = NSLocalizedString("ChatScene.Actions.Name", comment: "Chat: 'Name' field in actions menu")
		
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
	// MARK: Dependencies
	var chatsProvider: ChatsProvider!
	var dialogService: DialogService!
	var router: Router!
    var addressBookService: AddressBookService!
	
	// MARK: Properties
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
	
	var cellUpdateTimers: [Timer] = [Timer]()
	var cellsUpdating: [IndexPath] = [IndexPath]()
    
    internal var showsDateHeaderAfterTimeInterval: TimeInterval = 3600
	
	private var isFirstLayout = true
	
	// MARK: Fee label
	private var feeIsVisible: Bool = false
	private var feeTimer: Timer?
	private var feeLabel: InputBarButtonItem?
	private var prevFee: Decimal = 0
	
	
	// MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .plain, target: self, action: #selector(properties))
		
		guard let chatroom = chatroom else {
			return
		}
		
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
		
		// MARK: 1. Initial configuration
		
        updateTitle()
        
		messagesCollectionView.messagesDataSource = self
		messagesCollectionView.messagesDisplayDelegate = self
		messagesCollectionView.messagesLayoutDelegate = self
		messagesCollectionView.messageCellDelegate = self
		maintainPositionOnKeyboardFrameChanged = true
        
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            for messageSizeCalculator in layout.messageSizeCalculators() {
                messageSizeCalculator.outgoingAvatarSize = .zero
                messageSizeCalculator.incomingAvatarSize = .zero
                messageSizeCalculator.outgoingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 16))
                messageSizeCalculator.incomingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 2, left: 16, bottom: 0, right: 0))
                messageSizeCalculator.outgoingMessageTopLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 16))
            }
        }
		
		
		// MARK: 2. InputBar configuration
		
		messageInputBar.delegate = self
		
		let bordersColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1)
		let size: CGFloat = 6.0
		let buttonHeight: CGFloat = 36
		let buttonWidth: CGFloat = 46
		
		// Text & Colors
		messageInputBar.inputTextView.placeholder = String.adamantLocalized.chat.messageInputPlaceholder
		messageInputBar.separatorLine.backgroundColor = bordersColor
		messageInputBar.inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
		messageInputBar.inputTextView.layer.borderColor = bordersColor.cgColor
		messageInputBar.inputTextView.layer.borderWidth = 1.0
		messageInputBar.inputTextView.layer.cornerRadius = size*2
		messageInputBar.inputTextView.layer.masksToBounds = true
		
		// Insets
		messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: size, left: size*2, bottom: size, right: buttonWidth + size/2)
		messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: size, left: size*2+4, bottom: size, right: buttonWidth + size/2+2)
		messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
		messageInputBar.textViewPadding.right = -buttonWidth
		
		messageInputBar.setRightStackViewWidthConstant(to: buttonWidth, animated: false)
		
		// Make feeLabel
		let feeLabel = InputBarButtonItem()
		self.feeLabel = feeLabel
		feeLabel.isEnabled = false
		feeLabel.titleLabel?.font = UIFont.systemFont(ofSize: 12)
		feeLabel.alpha = 0
		
		// Setup stack views
		messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
		messageInputBar.setStackViewItems([feeLabel, .flexibleSpace], forStack: .bottom, animated: false)
		
		messageInputBar.sendButton.configure {
			$0.layer.cornerRadius = size*2
			$0.layer.borderWidth = 1
			$0.layer.borderColor = bordersColor.cgColor
			$0.setSize(CGSize(width: buttonWidth, height: buttonHeight), animated: false)
			$0.title = nil
			$0.image = #imageLiteral(resourceName: "Arrow")
			$0.setImage(#imageLiteral(resourceName: "Arrow_innactive"), for: UIControlState.disabled)
		}
		
		if let delegate = delegate, let address = chatroom.partner?.address, let message = delegate.getPreservedMessageFor(address: address, thenRemoveIt: true) {
			messageInputBar.inputTextView.text = message
			setEstimatedFee(AdamantMessage.text(message).fee)
		}
		
		// MARK: 3. Readonly chat
		
		if chatroom.isReadonly {
			messageInputBar.inputTextView.backgroundColor = UIColor.adamantChatSenderBackground
			messageInputBar.inputTextView.isEditable = false
			messageInputBar.sendButton.isEnabled = false
		}
		
		
		// MARK: 4. Data
		let controller = chatsProvider.getChatController(for: chatroom)
		chatController = controller
		controller.delegate = self
		
		do {
			try controller.performFetch()
		} catch {
			print("There was an error performing fetch: \(error)")
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		chatroom?.markAsReaded()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if let delegate = delegate, let message = messageInputBar.inputTextView.text, let address = chatroom?.partner?.address {
			delegate.preserveMessage(message, forAddress: address)
		}
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if isFirstLayout {
			isFirstLayout = false
			messagesCollectionView.scrollToBottom(animated: false)
		}
	}
	
	deinit {
		for timer in cellUpdateTimers {
			timer.invalidate()
		}
		
		cellUpdateTimers.removeAll()
	}
	
    func updateTitle() {
        if let partner = chatroom?.partner {
            if let name = partner.name {
                self.navigationItem.title = name
            } else {
                self.navigationItem.title = partner.address
            }
            
            if let address = partner.address, let name = self.addressBookService.addressBook[address] {
                self.navigationItem.title = name
            }
        }
    }
	
	// MARK: IBAction
	
	@IBAction func properties(_ sender: Any) {
		guard let partner = chatroom?.partner, let address = partner.address else {
			return
		}
		
		let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
		
		if partner.isSystem {
			dialogService.presentShareAlertFor(string: encodedAddress,
											   types: [.copyToPasteboard, .share, .generateQr(sharingTip: address)],
											   excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
											   animated: true,
											   completion: nil)
			
			return
		}
		
		let share = UIAlertAction(title: ShareType.share.localized, style: .default) { [weak self] action in
			self?.dialogService.presentShareAlertFor(string: encodedAddress,
													types: [.copyToPasteboard, .share, .generateQr(sharingTip: address)],
													excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
													animated: true,
													completion: nil)
		}
		
		let rename = UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak self] action in
			let alert = UIAlertController(title: String.adamantLocalized.chat.rename, message: String(format: String.adamantLocalized.chat.actionsBody, address), preferredStyle: .alert)
			
			alert.addTextField { (textField) in
				textField.placeholder = String.adamantLocalized.chat.name
				textField.autocapitalizationType = .words
				
				if let name = self?.addressBookService.addressBook[address] {
					textField.text = name
				}
			}
			
			alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.ok, style: .default) { [weak alert] (_) in
				if let textField = alert?.textFields?.first, let newName = textField.text {
					self?.addressBookService.set(name: newName, for: address)
					self?.updateTitle()
				}
			})
			
			alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
			
			self?.present(alert, animated: true, completion: nil)
		}
		
		dialogService.showSystemActionSheet(title: nil, message: nil, actions: [share, rename])
	}
}



// MARK: - EstimatedFee label
extension ChatViewController {
	func setEstimatedFee(_ fee: Decimal) {
		if prevFee != fee && fee > 0 {
			guard let feeLabel = feeLabel else {
				return
			}
			
			let text = "~\(AdamantUtilities.format(balance: fee))"
			prevFee = fee
			
			feeLabel.title = text
			feeLabel.setSize(CGSize(width: feeLabel.titleLabel!.intrinsicContentSize.width, height: 20), animated: false)
		}
		
		if !feeIsVisible && fee > 0 {
			feeIsVisible = true
			feeTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
				DispatchQueue.main.async {
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
		
		if type == .insert, let trs = anObject as? MessageTransaction {
			trs.isUnread = false
			chatroom?.hasUnreadMessages = false
		}
		
		if controllerChanges[type] == nil {
			controllerChanges[type] = [(IndexPath?, IndexPath?)]()
		}
		controllerChanges[type]!.append((indexPath, newIndexPath))
	}
	
	private func performBatchChanges(_ changes: [NSFetchedResultsChangeType:[(indexPath: IndexPath?, newIndexPath: IndexPath?)]]) {
		for (type, change) in changes {
			switch type {
			case .insert:
				let sections = IndexSet(change.compactMap {$0.newIndexPath?.row})
				if sections.count > 0 {
					messagesCollectionView.insertSections(sections)
					messagesCollectionView.scrollToBottom(animated: true)
				}
				
			case .delete:
				let sections = IndexSet(change.compactMap {$0.indexPath?.row})
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
				let indexes = change.compactMap { (indexPath: IndexPath?, _) -> IndexPath? in
					if let row = indexPath?.row {
						return IndexPath(row: 0, section: row)
					} else {
						return nil
					}
				}
				messagesCollectionView.reloadItems(at: indexes)
				return
			}
		}
	}
}
