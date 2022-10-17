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
import CoreData
import SafariServices
import ProcedureKit
import SnapKit

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
        
        static let noMailAppWarning = NSLocalizedString("ChatScene.Warning.NoMailApp", comment: "Chat: warning message for opening email link without mail app configurated on device")
        static let unsupportedUrlWarning = NSLocalizedString("ChatScene.Warning.UnsupportedUrl", comment: "Chat: warning message for opening unsupported url schemes")
        
        static let block = NSLocalizedString("Chats.Block", comment: "Block")
        
        static let remove = NSLocalizedString("Chats.Remove", comment: "Remove")
        static let removeMessage = NSLocalizedString("Chats.RemoveMessage", comment: "Delete this message?")
        static let report = NSLocalizedString("Chats.Report", comment: "Report")
        static let reportMessage = NSLocalizedString("Chats.ReportMessage", comment: "Report as inappropriate?")
        static let reportSent = NSLocalizedString("Chats.ReportSent", comment: "Report has been sent")
        
        static let freeTokens = NSLocalizedString("ChatScene.FreeTokensAlert.FreeTokens", comment: "Chat: 'Free Tokens' button")
        static let freeTokensMessage = NSLocalizedString("ChatScene.FreeTokensAlert.Message", comment: "Chat: 'Free Tokens' message")
        
        private init() { }
    }
}

// MARK: - Delegate
protocol ChatViewControllerDelegate: AnyObject {
    func preserveMessage(_ message: String, forAddress address: String)
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String?
}

// MARK: -
class ChatViewController: MessagesViewController {
    // MARK: Dependencies
    var chatsProvider: ChatsProvider!
    var transfersProvider: TransfersProvider!
    var dialogService: DialogService!
    var router: Router!
    var addressBookService: AddressBookService!
    var stack: CoreDataStack!
    var securedStore: SecuredStore!
    
    // MARK: Properties
    weak var delegate: ChatViewControllerDelegate?
    var account: AdamantAccount?
    var chatroom: Chatroom?
    var messageToShow: MessageTransaction?
    var forceScrollToBottom: Bool?
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    private var chatLoadNotificationObserver: NSObjectProtocol?
    
    private var keyboardManager = KeyboardManager()
    
    private(set) var chatController: NSFetchedResultsController<ChatTransaction>?
    
    /*
     In SplitViewController on iPhones, viewController can still present in memory, but not on screen.
     In this cases not visible viewController will still mark messages isUnread = false
     */
    /// ViewController currently is ontop of the screen.
    private var isOnTop = false
    
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
    private var didLoaded = false
    
    private var keyboardHeight: CGFloat = 0
    private let chatPositionDelata: CGFloat = 150
    private var chatPositionOffset: CGFloat = 0 {
        didSet {
            self.scrollToBottomBtn.isHidden = chatPositionOffset < chatPositionDelata
        }
    }
    var scrollToBottomBtnOffsetConstraint: NSLayoutConstraint?
    
    let scrollToBottomBtn = UIButton(type: .custom)
    
    var feeUpdateTimer: Timer?
    
    private let headerHeight: CGFloat = 38
    
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
    
    private let averageVisibleCount = 8
    
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
                navigator.modalPresentationStyle = .overFullScreen
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
    
    // MARK: Busy indicator
    
    private(set) var isBusy = false
    private var loadingView: LoadingView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "•••", style: .plain, target: self, action: #selector(properties))
        
        guard let chatroom = chatroom else {
            return
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        // MARK: 1. Initial configuration
        
        updateTitle()
        updateUI()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messageCellDelegate = self
        maintainPositionOnKeyboardFrameChanged = true
        
        messagesCollectionView.register(HeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)

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
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: size+2, left: size*2, bottom: size-2, right: size*2)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: size+2, left: size*2+4, bottom: size-2, right: size*2)
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
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
        messageInputBar.leftStackView.alignment = .bottom
        messageInputBar.setLeftStackViewWidthConstant(to: ChatViewController.attachmentButtonSize + size*2, animated: false)
        messageInputBar.leftStackView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: size*2)
        messageInputBar.leftStackView.isLayoutMarginsRelativeArrangement = true
        
        messageInputBar.sendButton.configure {
            $0.layer.cornerRadius = size*2
            $0.layer.borderWidth = 1
            $0.layer.borderColor = bordersColor.cgColor
            $0.tintColor = UIColor.adamant.primary
            $0.setSize(CGSize(width: buttonWidth, height: buttonHeight), animated: false)
            $0.title = nil
            $0.image = #imageLiteral(resourceName: "Arrow")
        }
        
        messageInputBar.inputTextView.autocorrectionType = .no
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            self.edgesForExtendedLayout = UIRectEdge.top
            
            view.addSubview(messageInputBar)
            keyboardManager.bind(inputAccessoryView: messageInputBar, usingTabBar: self.tabBarController?.tabBar)
            keyboardManager.bind(to: messagesCollectionView)
            scrollsToBottomOnKeyboardBeginsEditing = true
        }
        
        if let delegate = delegate, let address = chatroom.partner?.address, let message = delegate.getPreservedMessageFor(address: address, thenRemoveIt: true) {
            if !message.isEmpty {
                messageInputBar.inputTextView.text = message
            }
            setEstimatedFee(AdamantMessage.text(message).fee)
        }
        
        // MARK: 3. Data
        let controller = chatsProvider.getChatController(for: chatroom)
        chatController = controller
        controller.delegate = self
        
        do {
            try controller.performFetch()
        } catch {
            print("There was an error performing fetch: \(error)")
        }
        
        // MARK: Rich messages
        if let fetched = controller.fetchedObjects {
            for case let rich as RichMessageTransaction in fetched {
                rich.kind = messageKind(for: rich)
            }
            
            if let chatroom = self.chatroom, let message = chatroom.getFirstUnread() as? MessageTransaction {
                messageToShow = message
            }
        }
        
        // MARK: RichMessage handlers
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
        
        let h = messageInputBar.bounds.height
        
        scrollToBottomBtn.backgroundColor = .clear
        scrollToBottomBtn.setImage(#imageLiteral(resourceName: "ScrollDown"), for: .normal)
        scrollToBottomBtn.alpha = 0.5
        scrollToBottomBtn.frame = CGRect.zero
        scrollToBottomBtn.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomBtn.addTarget(self, action: #selector(scrollDown), for: .touchUpInside)
        scrollToBottomBtn.isHidden = true
        self.view.addSubview(scrollToBottomBtn)
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad, !isMacOS {
            setKeyboardObservers()
        }
        
        scrollToBottomBtnOffsetConstraint = scrollToBottomBtn.bottomAnchor.constraint(equalTo: messagesCollectionView.bottomAnchor, constant: (-20 - h))
        
        NSLayoutConstraint.activate([
            scrollToBottomBtn.heightAnchor.constraint(equalToConstant: 30),
            scrollToBottomBtn.widthAnchor.constraint(equalToConstant: 30),
            scrollToBottomBtn.rightAnchor.constraint(equalTo: messagesCollectionView.rightAnchor, constant: -20),
            scrollToBottomBtnOffsetConstraint!
        ])
        
        UIMenuController.shared.menuItems = [
            UIMenuItem(title: String.adamantLocalized.chat.remove, action: NSSelectorFromString("remove:")),
            UIMenuItem(title: String.adamantLocalized.chat.report, action: NSSelectorFromString("report:"))]
        
        loadFirstMessagesIfNeeded()
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {

        switch action {
        case NSSelectorFromString("remove:"): return true
        case NSSelectorFromString("report:"): return true
        default:
            return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {

        switch action {
        case NSSelectorFromString("remove:"): removeMessage(at: indexPath)
        case NSSelectorFromString("report:"): reportMessage(at: indexPath)
        default:
            super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
        }
    }
    
    func removeMessage(at indexPath: IndexPath) {
        self.dialogService.showAlert(title: String.adamantLocalized.chat.removeMessage, message: nil, style: .alert, actions: [
            AdamantAlertAction(title: String.adamantLocalized.alert.ok, style: .destructive, handler: {
            self.hideMessage(at: indexPath)
        }),
        AdamantAlertAction(title: String.adamantLocalized.alert.cancel, style: .default, handler: {
            //
        })], from: nil)
    }
    
    func reportMessage(at indexPath: IndexPath) {
        self.dialogService.showAlert(title: String.adamantLocalized.chat.reportMessage, message: nil, style: .alert, actions: [
            AdamantAlertAction(title: String.adamantLocalized.alert.ok, style: .destructive, handler: {
                self.hideMessage(at: indexPath, show: true)
        }),
        AdamantAlertAction(title: String.adamantLocalized.alert.cancel, style: .default, handler: {
            //
        })], from: nil)
    }
    
    func hideMessage(at indexPath: IndexPath, show: Bool = false) {
        let message = messageForItem(at: indexPath, in: self.messagesCollectionView)
        
        if let item = message as? ChatTransaction {
            print("\(message.messageId)")
            print(type(of: message.self))
            print(item.isHidden)
            
            item.isHidden = true
            try? item.managedObjectContext?.save()
            
            chatroom?.updateLastTransaction()
            
            if let transactionId = item.transactionId {
                chatsProvider.removeMessage(with: transactionId)
            }
            
            if show {
                self.dialogService.showToastMessage( String.adamantLocalized.chat.reportSent )
            }
        }
    }
    
    @objc func scrollDown() {
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isOnTop = true
        chatroom?.markAsReaded()
        
        scrollToBottomBtn.isHidden = chatPositionOffset < chatPositionDelata
        updateScrollToBottomBtnOffsetConstraint()
        
        if forceScrollToBottom ?? false && !scrollToBottomBtn.isHidden {
            scrollDown()
        }
        
        didLoaded = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isOnTop = false
        if let delegate = delegate, let message = messageInputBar.inputTextView.text, let address = chatroom?.partner?.address {
            delegate.preserveMessage(message, forAddress: address)
        }
        
        guard let address = chatroom?.partner?.address else { return }
        
        if self.chatPositionOffset > 0 {
            self.chatsProvider.chatPositon[address] = Double(self.chatPositionOffset)
        } else {
            self.chatsProvider.chatPositon.removeValue(forKey: address)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let address = chatroom?.partner?.address else { return }
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            let barHeight = messageInputBar.frame.height
            messageInputBar.frame.origin.y = view.bounds.maxY - keyboardHeight - barHeight
            additionalBottomInset = barHeight
        }
        
        // MARK: Scroll to message
        if let messageToShow = self.messageToShow {
            if let indexPath = chatController?.indexPath(forObject: messageToShow) {
                self.messagesCollectionView.scrollToItem(at: IndexPath(item: 0, section: indexPath.row), at: [.centeredVertically, .centeredHorizontally], animated: false)
                isFirstLayout = false
                self.chatsProvider.chatPositon.removeValue(forKey: address)
                self.messageToShow = nil

                didLoaded = true
                if indexPath.row >= 0 && indexPath.row <= averageVisibleCount {
                    self.loadMooreMessagesIfNeeded(indexPath: IndexPath(row: 0, section: 2))
                    self.reloadTopSectionIfNeeded()
                }
                return
            }
        }
        
        if isFirstLayout {
            isFirstLayout = false
            
            if self.messageToShow == nil {
                if let offset = self.chatsProvider.chatPositon[address] {
                    self.chatPositionOffset = CGFloat(offset)
                    self.scrollToBottomBtn.isHidden = chatPositionOffset < chatPositionDelata
                    let collectionViewContentHeight = messagesCollectionView.collectionViewLayout.collectionViewContentSize.height - CGFloat(offset) - (messagesCollectionView.scrollIndicatorInsets.bottom + messagesCollectionView.contentInset.bottom) + headerHeight

                    messagesCollectionView.performBatchUpdates(nil) { _ in self.messagesCollectionView.scrollRectToVisible(CGRect(x: 0.0, y: collectionViewContentHeight - 1.0, width: 1.0, height: 1.0), animated: false)
                    }
                } else {
                    messagesCollectionView.scrollToBottom(animated: false)
                }
            } else {
                self.chatsProvider.chatPositon.removeValue(forKey: address)
            }
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
        
        if let chatLoadNotificationObserver = chatLoadNotificationObserver {
            NotificationCenter.default.removeObserver(chatLoadNotificationObserver)
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
                self.navigationItem.title = name.checkAndReplaceSystemWallets()
            }
        }
    }
    
    func close() {
        if let tabVC = tabBarController, let selectedView = tabVC.selectedViewController, let nav = selectedView.children.first as? UINavigationController {
                nav.popToRootViewController(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func addChatLoadObserver() {
        chatLoadNotificationObserver = NotificationCenter.default.addObserver(forName: .AdamantChatsProvider.initiallyLoadedMessages, object: nil, queue: .main) { [weak self] notification in
            guard let recipientAddress = notification.object as? String,
                  recipientAddress == self?.chatroom?.partner?.address
            else { return }
            self?.updateChatMessages()
        }
    }
    
    func updateUI() {
        view.backgroundColor = UIColor.adamant.backgroundColor
        messagesCollectionView.backgroundColor = UIColor.adamant.backgroundColor
        messageInputBar.inputTextView.backgroundColor = UIColor.adamant.chatInputFieldBarBackground
        messageInputBar.backgroundView.backgroundColor = UIColor.adamant.chatInputBarBackground
        
        if messageInputBar.inputTextView.text.isEmpty {
            messageInputBar.sendButton.isEnabled = false
        }
        
        if chatroom?.isReadonly ?? false {
            messageInputBar.inputTextView.placeholder = ""
            messageInputBar.inputTextView.isEditable = false
            messageInputBar.sendButton.isEnabled = false
            attachmentButton.isEnabled = false
            messageInputBar.inputTextView.backgroundColor = UIColor.adamant.chatInputBarBackground
            messageInputBar.inputTextView.layer.borderColor = UIColor.adamant.disableBorderColor.cgColor
            messageInputBar.sendButton.layer.borderColor = UIColor.adamant.disableBorderColor.cgColor
            attachmentButton.layer.borderColor = UIColor.adamant.disableBorderColor.cgColor
        }
    }
    
    // MARK: IBAction
    
    @IBAction func properties(_ sender: UIBarButtonItem) {
        guard let partner = chatroom?.partner, let address = partner.address else {
            return
        }

        let params: [AdamantAddressParam]?
        if let name = partner.name {
            params = [.label(name)]
        } else {
            params = nil
        }

        let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address,
                                                                                params: params))
        
        if partner.isSystem {
            dialogService.presentShareAlertFor(string: address,
                                               types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)],
                                               excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                               animated: true,
                                               from: sender,
                                               completion: nil)
            
            return
        }
        
        let block = UIAlertAction(title: String.adamantLocalized.chat.block, style: .destructive) { _ in
            self.dialogService.showAlert(title: String.adamantLocalized.chatList.blockUser, message: nil, style: .alert, actions: [
                AdamantAlertAction(title: String.adamantLocalized.alert.ok, style: .destructive, handler: {
                    self.chatsProvider.blockChat(with: address)
                
                    self.chatroom?.isHidden = true
                    try? self.chatroom?.managedObjectContext?.save()
                    
                    self.close()
            }),
            AdamantAlertAction(title: String.adamantLocalized.alert.cancel, style: .default, handler: {
                //
            })], from: nil)
        }
        
        let share = UIAlertAction(title: ShareType.share.localized, style: .default) { [weak self] _ in
            self?.dialogService.presentShareAlertFor(string: address,
                                                     types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)],
                                                     excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                     animated: true,
                                                     from: sender,
                                                     completion: nil)
        }
        
        let rename = UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak self] _ in
            let alert = UIAlertController(title: String(format: String.adamantLocalized.chat.actionsBody, address), message: nil, preferredStyle: .alert)
            
            alert.addTextField { (textField) in
                textField.placeholder = String.adamantLocalized.chat.name
                textField.autocapitalizationType = .words
                
                if let name = self?.addressBookService.addressBook[address] {
                    textField.text = name.checkAndReplaceSystemWallets()
                }
            }
            
            alert.addAction(UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak alert] (_) in
                if let textField = alert?.textFields?.first, let newName = textField.text {
                    self?.addressBookService.set(name: newName, for: address)
                    self?.updateTitle()
                }
            })
            
            alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
            alert.modalPresentationStyle = .overFullScreen
            self?.present(alert, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil)
        
        dialogService?.showAlert(title: nil, message: nil, style: .actionSheet, actions: [block, share, rename, cancel], from: sender)
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
    
    private func setKeyboardObservers() {
        let keyboardObserver: (_ height: CGFloat) -> Void = { [weak self] height in
            self?.keyboardHeight = height
            self?.updateScrollToBottomBtnOffsetConstraint()
        }
        
        keyboardManager.on(event: .willChangeFrame) { [weak self] notification in
            let tabBarHeight = self?.tabBarController?.tabBar.frame.height ?? .zero
            let keyboardHeight = notification.endFrame.height - tabBarHeight
            keyboardObserver(keyboardHeight)
            self?.view.setNeedsLayout()
        }
        
        keyboardManager.on(event: .willHide) { _ in
            keyboardObserver(.zero)
        }
    }
    
    private func updateScrollToBottomBtnOffsetConstraint() {
        scrollToBottomBtnOffsetConstraint?.constant = -20 - keyboardHeight - messageInputBar.frame.height
    }
}

// MARK: - EstimatedFee label
extension ChatViewController {
    func setEstimatedFee(_ fee: Decimal) {
        if prevFee != fee && fee > 0 {
            guard let feeLabel = feeLabel else {
                return
            }
            
            let text = "~\(AdamantBalanceFormat.full.format(fee, withCurrencySymbol: AdmWalletService.currencySymbol))"
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
        if !isBusy {
            performBatchChanges(controllerChanges)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let trs = anObject as? ChatTransaction {
                if isOnTop {
                    trs.isUnread = false
                    chatroom?.hasUnreadMessages = false
                }
                
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
        
        var scrollToBottom = changes.first { $0.type == .insert } != nil
        var forceScrollToBottom = false
        
        if !isFirstLayout && changes.first?.type != nil {
            if self.forceScrollToBottom ?? false {
                scrollToBottom = true
                self.forceScrollToBottom = false
            } else {
                scrollToBottom = scrollToBottomBtn.isHidden
            }
        }
        
        chat.performBatchUpdates({
            for change in changes {
                switch change.type {
                case .insert:
                    guard let newIndexPath = change.newIndexPath else {
                        continue
                    }
                    
                    chat.insertSections(IndexSet(integer: newIndexPath.row))
                    if scrollToBottom {
                        chat.scrollToBottom(animated: true)
                        forceScrollToBottom = true
                    }
                    
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
                    if chat.indexPathsForVisibleItems.contains(IndexPath(row: 0, section: section)) {
                        chat.reloadItems(at: [IndexPath(row: 0, section: section)])
                    }
                    scrollToBottom = false
                @unknown default:
                    break
                }
            }
        }, completion: { animationSuccess in
            if scrollToBottom || forceScrollToBottom {
                chat.scrollToBottom(animated: animationSuccess)
            }
        })
    }
}

extension ChatViewController: TransferViewControllerDelegate, ComplexTransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        if transfer != nil {
            DispatchQueue.main.async {
                self.scrollDown()
            }
        }
        dismissTransferViewController(andPresent: detailsViewController)
    }
    
    func complexTransferViewController(_ viewController: ComplexTransferViewController, didFinishWithTransfer: TransactionDetails?, detailsViewController: UIViewController?) {
        if didFinishWithTransfer != nil {
            DispatchQueue.main.async {
                self.scrollDown()
            }
        }
        dismissTransferViewController(andPresent: detailsViewController)
    }
    
    private func dismissTransferViewController(andPresent viewController: UIViewController?) {
        DispatchQueue.onMainAsync { [weak self] in
            self?.dismiss(animated: true, completion: nil)
            
            if let viewController = viewController, let nav = self?.navigationController {
                nav.pushViewController(viewController, animated: true)
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offset = scrollView.contentSize.height - scrollView.bounds.height - scrollView.contentOffset.y + messageInputBar.bounds.height
        offset += self.keyboardHeight
        
        if offset > chatPositionDelata {
            chatPositionOffset = offset
        } else {
            chatPositionOffset = 0
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
        
        log.severity = .warning
    }
    
    override func execute() {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = parentContext
        
        guard let transaction = privateContext.object(with: objectId) as? RichMessageTransaction else {
            return
        }
        
        provider.statusFor(transaction: transaction) { result in
            switch result {
            case .success(let status):
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

// MARK: - Busy Indicator View
extension ChatViewController {
    func setupLoadingView() {
        let loadingView = LoadingView()
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        loadingView.startAnimating()
        self.loadingView = loadingView
    }
    
    func setBusyIndicator(state: Bool) {
        isBusy = state
        if loadingView == nil && state {
            setupLoadingView()
            messagesCollectionView.alpha = 0.0
            messageInputBar.inputTextView.isEditable = false
            messageInputBar.leftStackView.isUserInteractionEnabled = false
        }
        
        if !state {
            if loadingView != nil {
                reloadTopSectionIfNeeded()
            }
            
            if chatroom?.isReadonly ?? false {
                updateUI()
            } else {
                messageInputBar.inputTextView.isEditable = true
                messageInputBar.leftStackView.isUserInteractionEnabled = true
            }
            
            UIView.animate(withDuration: 0.25, delay: 0.25) { [weak self] in
                self?.messagesCollectionView.alpha = 1.0
                self?.loadingView?.alpha = 0.0
            } completion: { [weak self] _ in
                self?.loadingView?.removeFromSuperview()
            }
        }
    }
}

// MARK: Load moore message
extension ChatViewController {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
       loadMooreMessagesIfNeeded(indexPath: indexPath)
    }
    
    func loadFirstMessagesIfNeeded() {
        guard let address = chatroom?.partner?.address else { return }
        
        if let isLoaded = chatsProvider.isChatLoaded[address],
           isLoaded {
            setBusyIndicator(state: false)
            return
        }
        
        if address == AdamantContacts.adamantWelcomeWallet.name {
            setBusyIndicator(state: false)
            return
        }
        
        setBusyIndicator(state: true)
        
        if chatsProvider.isChatLoading(with: address) {
            addChatLoadObserver()
            return
        }
        
        chatsProvider.getChatMessages(with: address, offset: 0) { [weak self] in
            DispatchQueue.main.async {
                self?.updateChatMessages()
            }
        }
    }
    
    func updateChatMessages() {
        messagesCollectionView.reloadDataAndKeepOffset()
        messagesCollectionView.scrollToLastItem(animated: false)
        setBusyIndicator(state: false)
    }
    
    func loadMooreMessagesIfNeeded(indexPath: IndexPath) {
        guard indexPath.section < 4,
              let address = chatroom?.partner?.address,
              !isBusy,
              isNeedToLoadMoore(),
              didLoaded
        else {
            return
        }
        
        if address == AdamantContacts.adamantWelcomeWallet.name { return }
        isBusy = true
        let offset = chatsProvider.chatLoadedMessages[address] ?? 0
        chatsProvider.getChatMessages(with: address, offset: offset) { [weak self] in
            DispatchQueue.main.async {
                self?.messagesCollectionView.reloadDataAndKeepOffset()
                self?.isBusy = false
                self?.reloadTopSectionIfNeeded()
            }
        }
    }
    
    func reloadTopSectionIfNeeded() {
        try? chatController?.performFetch()
        if let count = chatController?.fetchedObjects?.count,
           count >= 1 {
            self.messagesCollectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    
    func isNeedToLoadMoore() -> Bool {
        if let address = chatroom?.partner?.address,
           chatsProvider.chatLoadedMessages[address] ?? 0 < chatsProvider.chatMaxMessages[address] ?? 0 {
            return true
        }
        return false
    }
}

// MARK: Mac OS HotKeys
extension ChatViewController {
    open override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(processEnter))
        ]
        if #available(iOS 15, *) {
            commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        }
        return commands
    }
    
    @objc private func processEnter() {
        if messageInputBar.inputTextView.isFirstResponder {
            messageInputBar.didSelectSendButton()
        } else {
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
}
