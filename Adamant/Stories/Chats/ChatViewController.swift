//
//  ChatViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 15.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import MessageKit
import MessageInputBar
import class InputBarAccessoryView.KeyboardManager
import CoreData
import SafariServices
import ProcedureKit

// MARK: - Localization
extension String.adamantLocalized {
	struct chat {
		static let sendButton = NSLocalizedString("ChatScene.Send", comment: "Chat: Send message button")
		static let messageInputPlaceholder = NSLocalizedString("ChatScene.NewMessage.Placeholder", comment: "Chat: message input placeholder")
		static let cancelError = NSLocalizedString("ChatScene.Error.cancelError", comment: "Chat: inform user that he can't cancel transaction, that was sent")
        static let failToSend = NSLocalizedString("ChatScene.MessageStatus.FailToSend", comment: "Chat: status message for failed to send chat transaction")
        static let pending = NSLocalizedString("ChatScene.MessageStatus.Pending", comment: "Chat: status message for pending chat transaction")
		
        static let actionsBody = NSLocalizedString("ChatScene.Actions.Body", comment: "Chat: Body for actions menu")
        static let rename = NSLocalizedString("ChatScene.Actions.Rename", comment: "Chat: 'Rename' action in actions menu")
        static let name = NSLocalizedString("ChatScene.Actions.NamePlaceholder", comment: "Chat: 'Name' field in actions menu")
		
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
    var stack: CoreDataStack!
	
	// MARK: Properties
	weak var delegate: ChatViewControllerDelegate?
	var account: AdamantAccount?
	var chatroom: Chatroom?
	var dateFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}
    
    private var keyboardManager = KeyboardManager()
	
	private(set) var chatController: NSFetchedResultsController<ChatTransaction>?
    
    // Batch changes
    private struct ControllerChange {
        let type: NSFetchedResultsChangeType
        let indexPath: IndexPath?
        let newIndexPath: IndexPath?
    }
    
	private var controllerChanges: [ControllerChange] = []
    
    private var skipRichInitialUpdate: [String] = []
	
    // Cell update timing
	var cellUpdateTimers: [Timer] = [Timer]()
	var cellsUpdating: [IndexPath] = [IndexPath]()
    
    internal var showsDateHeaderAfterTimeInterval: TimeInterval = 3600
	
	private var isFirstLayout = true
	
	// Content insets are broken after modal view dissapears
	private var fixKeyboardInsets = false
	
    // MARK: Rich Messages
    var richMessageProviders = [String:RichMessageProvider]()
    var cellCalculators = [String:CellSizeCalculator]()
    
    private var richMessageStatusUpdating = [NSManagedObjectID]()
    private let statusUpdatingSemaphore = DispatchSemaphore(value: 1)
    
    fileprivate func addRichMessageStatusUpdating(id: NSManagedObjectID) {
        statusUpdatingSemaphore.wait()
        defer { statusUpdatingSemaphore.signal() }
        
        if !richMessageStatusUpdating.contains(id) {
            richMessageStatusUpdating.append(id)
        }
    }
    
    fileprivate func removeRichMessageStatusUpdating(id: NSManagedObjectID) {
        statusUpdatingSemaphore.wait()
        defer { statusUpdatingSemaphore.signal() }
        
        guard let index = richMessageStatusUpdating.firstIndex(of: id) else {
            return
        }
        
        richMessageStatusUpdating.remove(at: index)
    }
    
    func isUpdatingRichMessageStatus(id: NSManagedObjectID) -> Bool {
        statusUpdatingSemaphore.wait()
        defer { statusUpdatingSemaphore.signal() }
        
        return richMessageStatusUpdating.contains(id)
    }
    
	// MARK: Fee label
	private var feeIsVisible: Bool = false
	private var feeTimer: Timer?
	private var feeLabel: InputBarButtonItem?
	private var prevFee: Decimal = 0
	
    // MARK: Attachment button
    static let attachmentButtonSize: CGFloat = 36.0
    
    lazy var attachmentButton: InputBarButtonItem = {
        return InputBarButtonItem()
            .configure {
                $0.setSize(CGSize(width: ChatViewController.attachmentButtonSize, height: ChatViewController.attachmentButtonSize), animated: false)
                $0.image = #imageLiteral(resourceName: "Attachment")
                $0.tintColor = UIColor.adamant.primary
            }.onTouchUpInside { [weak self] _ in
				guard let vc = self?.router.get(scene: AdamantScene.Chats.complexTransfer) as? ComplexTransferViewController else {
					return
				}
				
				vc.partner = self?.chatroom?.partner
				vc.transferDelegate = self
				
				let navigator = UINavigationController(rootViewController: vc)
				self?.present(navigator, animated: true, completion: nil)
            }
    }()
	
    // MARK: RichTransaction status updates
    private lazy var richQueueSemaphore = DispatchSemaphore(value: 1)
    private lazy var richStatusDispatchQueue = DispatchQueue(label: "com.adamant.chat.status-update.dispatch-queue", qos: .utility, attributes: [.concurrent])
    private lazy var richStatusOperationQueue: ProcedureQueue = {
        let queue = ProcedureQueue()
        queue.name = "com.adamant.chat.status-update.operation-queue"
        queue.underlyingQueue = richStatusDispatchQueue
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    
	// MARK: - Lifecycle
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
        messageInputBar.setStackViewItems([attachmentButton], forStack: .left, animated: false)
		
        // Add spacing between leftStackView (attachment button) and message input field
        messageInputBar.leftStackView.alignment = .leading
        messageInputBar.setLeftStackViewWidthConstant(to: ChatViewController.attachmentButtonSize + size*2, animated: false)
        messageInputBar.leftStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: size*2)
        messageInputBar.leftStackView.isLayoutMarginsRelativeArrangement = true
        
		messageInputBar.sendButton.configure {
			$0.layer.cornerRadius = size*2
			$0.layer.borderWidth = 1
			$0.layer.borderColor = bordersColor.cgColor
			$0.setSize(CGSize(width: buttonWidth, height: buttonHeight), animated: false)
			$0.title = nil
			$0.image = #imageLiteral(resourceName: "Arrow")
			$0.setImage(#imageLiteral(resourceName: "Arrow_innactive"), for: UIControl.State.disabled)
		}
		
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            view.addSubview(messageInputBar)
            keyboardManager.bind(inputAccessoryView: messageInputBar)
            keyboardManager.bind(to: messagesCollectionView)
            
            keyboardManager.on(event: .didChangeFrame) { [weak self] (notification) in
                let barHeight = self?.messageInputBar.bounds.height ?? 0
                self?.messagesCollectionView.contentInset.bottom = barHeight + notification.endFrame.height
                self?.messagesCollectionView.scrollIndicatorInsets.bottom = barHeight + notification.endFrame.height
                }.on(event: .didHide) { [weak self] _ in
                    let barHeight = self?.messageInputBar.bounds.height ?? 0
                    self?.messagesCollectionView.contentInset.bottom = barHeight
                    self?.messagesCollectionView.scrollIndicatorInsets.bottom = barHeight
            }
        }
        
		if let delegate = delegate, let address = chatroom.partner?.address, let message = delegate.getPreservedMessageFor(address: address, thenRemoveIt: true) {
			messageInputBar.inputTextView.text = message
			setEstimatedFee(AdamantMessage.text(message).fee)
		}
		
		// MARK: 3. Readonly chat
		
		if chatroom.isReadonly {
			messageInputBar.inputTextView.backgroundColor = UIColor.adamant.chatSenderBackground
			messageInputBar.inputTextView.isEditable = false
			messageInputBar.sendButton.isEnabled = false
            attachmentButton.isEnabled = false
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
        
        // MARK: 4.1 Rich messages
        if let fetched = controller.fetchedObjects {
            for case let rich as RichMessageTransaction in fetched {
                rich.kind = messageKind(for: rich)
            }
        }
		
		// MARK: 5. Notifications
		// Fixing content insets after modal window
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main) { [weak self] notification in
			guard let fixIt = self?.fixKeyboardInsets, fixIt else {
				return
			}
			
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
				let scrollView = self?.messagesCollectionView else {
				return
			}
			
			var contentInsets = scrollView.contentInset
			contentInsets.bottom = frame.size.height
			scrollView.contentInset = contentInsets
			
			var scrollIndicatorInsets = scrollView.scrollIndicatorInsets
			scrollIndicatorInsets.bottom = frame.size.height
			scrollView.scrollIndicatorInsets = scrollIndicatorInsets
			
			scrollView.scrollToBottom(animated: true)
			
			self?.fixKeyboardInsets = false
		}
        
        // MARK: 6. RichMessage handlers
        for handler in richMessageProviders.values {
            if let source = handler.cellSource {
                switch source {
                case .class(let type):
                    messagesCollectionView.register(type, forCellWithReuseIdentifier: handler.cellIdentifierSent)
                    messagesCollectionView.register(type, forCellWithReuseIdentifier: handler.cellIdentifierReceived)
                    
                case .nib(let nib):
                    messagesCollectionView.register(nib, forCellWithReuseIdentifier: handler.cellIdentifierSent)
                    messagesCollectionView.register(nib, forCellWithReuseIdentifier: handler.cellIdentifierReceived)
                }
            }
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
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            messagesCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        }
		
		if isFirstLayout {
			isFirstLayout = false
			messagesCollectionView.scrollToBottom(animated: false)
		}
	}
    
    override var inputAccessoryView: UIView? {
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            return nil
        } else {
            return super.inputAccessoryView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            return false
        } else {
            return true
        }
    }
	
	deinit {
		for timer in cellUpdateTimers {
			timer.invalidate()
		}
		
		cellUpdateTimers.removeAll()
        richStatusOperationQueue.cancelAllOperations()
        
        if richMessageStatusUpdating.count > 0 {
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.parent = stack.container.viewContext
            
            let transactions = richMessageStatusUpdating.compactMap { privateContext.object(with: $0) as? RichMessageTransaction }
            
            for transaction in transactions where transaction.transactionStatus == .updating {
                transaction.transactionStatus = .notInitiated
            }
            
            try? privateContext.save()
        }
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
	
	@IBAction func properties(_ sender: UIBarButtonItem) {
		guard let partner = chatroom?.partner, let address = partner.address else {
			return
		}
		
        let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
		
		if partner.isSystem {
			dialogService.presentShareAlertFor(string: address,
                                               types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)],
											   excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                               animated: true, from: sender,
											   completion: nil)
			
			return
		}
		
		let share = UIAlertAction(title: ShareType.share.localized, style: .default) { [weak self] action in
			self?.dialogService.presentShareAlertFor(string: address,
                                                     types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)],
													excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                    animated: true, from: sender,
													completion: nil)
		}
		
		let rename = UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak self] action in
			let alert = UIAlertController(title: String(format: String.adamantLocalized.chat.actionsBody, address), message: nil, preferredStyle: .alert)
			
			alert.addTextField { (textField) in
				textField.placeholder = String.adamantLocalized.chat.name
				textField.autocapitalizationType = .words
				
				if let name = self?.addressBookService.addressBook[address] {
					textField.text = name
				}
			}
			
			alert.addAction(UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak alert] (_) in
				if let textField = alert?.textFields?.first, let newName = textField.text {
					self?.addressBookService.set(name: newName, for: address)
					self?.updateTitle()
				}
			})
			
			alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
			
			self?.present(alert, animated: true, completion: nil)
		}
		
        let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil)
        
        dialogService?.showAlert(title: nil, message: nil, style: .actionSheet, actions: [share, rename, cancel], from: sender)
	}
    
    
    // MARK: Tools
    private func messageKind(for richMessage: RichMessageTransaction) -> MessageKind {
        guard let type = richMessage.richType else {
            return MessageKind.text(richMessage.richType ?? "Failed to read richmessage id: \(richMessage.txId)")
        }
        
        guard var richContent = richMessage.richContent else {
            fatalError()
        }
        
        if richMessageProviders[type] != nil, let richMessageTransfer = RichMessageTransfer(content: richContent) {
            return MessageKind.custom(richMessageTransfer)
        } else {
            if richContent[RichContentKeys.type] == nil {
                richContent[RichContentKeys.type] = type
            }
            
            do {
                let raw = try JSONSerialization.data(withJSONObject: richContent, options: [])
                let serialized = String(data: raw, encoding: String.Encoding.utf8)!
                return MessageKind.text(serialized)
            } catch {
                return MessageKind.text("Failed to read rich message: \(error.localizedDescription)")
            }
        }
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
        
        switch type {
        case .insert:
            if let trs = anObject as? ChatTransaction {
                trs.isUnread = false
                chatroom?.hasUnreadMessages = false
                
                if let rich = anObject as? RichMessageTransaction {
                    rich.kind = messageKind(for: rich)
                }
            }
            
        case .update:
            if let rich = anObject as? RichMessageTransaction, let index = skipRichInitialUpdate.firstIndex(of: rich.messageId) {
                skipRichInitialUpdate.remove(at: index)
                return
            }
            
        default: break
        }
		
        controllerChanges.append(ControllerChange(type: type, indexPath: indexPath, newIndexPath: newIndexPath))
	}
	
	private func performBatchChanges(_ changes: [ControllerChange]) {
        let chat = messagesCollectionView
        
        let scrollToBottom = changes.first { $0.type == .insert } != nil
        
        chat.performBatchUpdates({
            for change in changes {
                switch change.type {
                case .insert:
                    guard let newIndexPath = change.newIndexPath else {
                        continue
                    }
                    
                    chat.insertSections(IndexSet(integer: newIndexPath.row))
                    chat.scrollToBottom(animated: true)
                    
                case .delete:
                    guard let indexPath = change.indexPath else {
                        continue
                    }
                    
                    chat.deleteSections(IndexSet(integer: indexPath.row))
                    
                case .move:
                    if let section = change.indexPath?.row, let newSection = change.newIndexPath?.row {
                        chat.moveSection(section, toSection: newSection)
                    }
                    
                case .update:
                    guard let section = change.indexPath?.row else {
                        continue
                    }
                    
                    chat.reloadItems(at: [IndexPath(row: 0, section: section)])
                }
            }
        }, completion: { animationSuccess in
            if scrollToBottom {
                chat.scrollToBottom(animated: animationSuccess)
            }
        })
	}
}

extension ChatViewController: TransferViewControllerDelegate, ComplexTransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        dismissTransferViewController(andPresent: detailsViewController)
    }
	
    func complexTransferViewController(_ viewController: ComplexTransferViewController, didFinishWithTransfer: TransactionDetails?, detailsViewController: UIViewController?) {
        dismissTransferViewController(andPresent: detailsViewController)
    }
	
    private func dismissTransferViewController(andPresent viewController: UIViewController?) {
		fixKeyboardInsets = true
		
		if Thread.isMainThread {
			dismiss(animated: true, completion: nil)
            
            if let viewController = viewController, let nav = navigationController {
                nav.pushViewController(viewController, animated: true)
            }
		} else {
			DispatchQueue.main.async { [weak self] in
				self?.dismiss(animated: true, completion: nil)
                
                if let viewController = viewController, let nav = self?.navigationController {
                    nav.pushViewController(viewController, animated: true)
                }
            }
		}
	}
}

// MARK: - RichTransfers status update
extension ChatViewController {
    func updateStatus(for transaction: RichMessageTransaction, provider: RichMessageProviderWithStatusCheck, delay: TimeInterval? = nil) {
        guard transaction.transactionStatus != .updating else {
            return
        }
        
        if transaction.transactionStatus == nil || transaction.transactionStatus == .notInitiated {
            skipRichInitialUpdate.append(transaction.messageId)
        }
        
        transaction.transactionStatus = .updating
        let objectID = transaction.objectID
        
        richMessageStatusUpdating.append(objectID)
        
        let operation = StatusUpdateProcedure(parentContext: stack.container.viewContext,
                                              objectId: objectID,
                                              provider: provider,
                                              controller: self)
        
        if let delay = delay {
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let semaphore = self?.richQueueSemaphore, let queue = self?.richStatusOperationQueue else {
                    return
                }
                
                semaphore.wait()
                queue.addOperation(operation)
                semaphore.signal()
            }
        } else {
            richQueueSemaphore.wait()
            richStatusOperationQueue.addOperation(operation)
            richQueueSemaphore.signal()
        }
    }
}

private class StatusUpdateProcedure: Procedure {
    // MARK: Props
    let parentContext: NSManagedObjectContext
    let objectId: NSManagedObjectID
    let provider: RichMessageProviderWithStatusCheck
    
    weak var controller: ChatViewController?
    
    init(parentContext: NSManagedObjectContext, objectId: NSManagedObjectID, provider: RichMessageProviderWithStatusCheck, controller: ChatViewController) {
        self.parentContext = parentContext
        self.objectId = objectId
        self.provider = provider
        self.controller = controller
        super.init()
    }
    
    override func execute() {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = parentContext
        
        guard let transaction = privateContext.object(with: objectId) as? RichMessageTransaction else {
            return
        }
        
        guard let txHash = transaction.richContent?[RichContentKeys.transfer.hash] else {
            transaction.transactionStatus = .failed
            try? privateContext.save()
            return
        }
        
        provider.statusForTransactionBy(hash: txHash) { result in
            switch result {
            case .success(let status):
                if let date = transaction.dateValue {
                    let timeAgo = -1 * date.timeIntervalSinceNow
                    
                    if status == .pending, timeAgo > 60 * 60 * 3 { // 3h waiting for panding status
                        transaction.transactionStatus = .failed
                        break
                    }
                }
                
                transaction.transactionStatus = status
                
                if status == .pending {
                    // 'self' is destroyed right after completion of this clousure, so we need to hold references
                    weak var controller = self.controller
                    weak var provider = self.provider
                    weak var context = self.parentContext
                    
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + self.provider.delayBetweenChecks) {
                        guard let controller = controller, let provider = provider else {
                            return
                        }
                        
                        guard let trs = context?.object(with: transaction.objectID) as? RichMessageTransaction else {
                            return
                        }
                        
                        controller.updateStatus(for: trs, provider: provider, delay: 2.0)
                    }
                } else {
                    self.controller?.removeRichMessageStatusUpdating(id: self.objectId)
                }

            case .failure:
                transaction.transactionStatus = .failed
                self.controller?.removeRichMessageStatusUpdating(id: self.objectId)
            }

            try? privateContext.save()
            self.finish()
        }
    }
}
