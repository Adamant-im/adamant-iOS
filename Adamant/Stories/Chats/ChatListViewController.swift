//
//  ChatListViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData
import MarkdownKit

extension String.adamantLocalized {
    struct chatList {
        static let title = NSLocalizedString("ChatListPage.Title", comment: "ChatList: scene title")
        static let sentMessagePrefix = NSLocalizedString("ChatListPage.SentMessagePrefix", comment: "ChatList: outgoing message prefix")
        static let syncingChats = NSLocalizedString("ChatListPage.SyncingChats", comment: "ChatList: First syncronization is in progress")
        static let searchPlaceholder = NSLocalizedString("ChatListPage.SearchBar.Placeholder", comment: "ChatList: SearchBar placeholder text")
        
        static let blockUser = NSLocalizedString("Chats.BlockUser", comment: "Block this user?")
        
        private init() {}
    }
}

class ChatListViewController: UIViewController {
    let cellIdentifier = "cell"
    let cellHeight: CGFloat = 76.0
    
    // MARK: Dependencies
    var accountService: AccountService!
    var chatsProvider: ChatsProvider!
    var transfersProvider: TransfersProvider!
    var router: Router!
    var notificationsService: NotificationsService!
    var dialogService: DialogService!
    var addressBook: AddressBookService!
    var avatarService: AvatarService!
    
    var richMessageProviders = [String:RichMessageProvider]()
    
    // MARK: IBOutlet
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newChatButton: UIBarButtonItem!
    
    // MARK: Properties
    var chatsController: NSFetchedResultsController<Chatroom>?
    var unreadController: NSFetchedResultsController<ChatTransaction>?
    
    var searchController: UISearchController!
    
    private var preservedMessagess = [String:String]()
    
    let defaultAvatar = #imageLiteral(resourceName: "avatar-chat-placeholder")
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.adamant.primary
        return refreshControl
    }()
    
    private lazy var markdownParser: MarkdownParser = {
        let parser = MarkdownParser(font: UIFont.systemFont(ofSize: ChatTableViewCell.shortDescriptionTextSize),
                                    color: UIColor.adamant.primary,
                                    enabledElements: .disabledAutomaticLink)
        
        parser.link.color = UIColor.adamant.active
        
        return parser
    }()
    
    // MARK: Busy indicator
    
    @IBOutlet weak var busyBackgroundView: UIView!
    @IBOutlet weak var busyIndicatorView: UIView!
    @IBOutlet weak var busyIndicatorLabel: UILabel!
    
    private(set) var isBusy: Bool = true
    
    // MARK: Keyboard
    // SplitView sends double notifications about keyboard.
    private var originalInsets: UIEdgeInsets?
    private var didShow: Bool = false
    
    var didLoadedMessages: (() ->())?
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .never
        }

        navigationItem.title = String.adamantLocalized.chatList.title
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat)),
            UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(beginSearch))
        ]
        
        // MARK: TableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.refreshControl = refreshControl
        
        if self.accountService.account != nil {
            initFetchedRequestControllers(provider: chatsProvider)
        }
        
        // MARK: Search controller
        guard let searchResultController = router.get(scene: AdamantScene.Chats.searchResults) as? SearchResultsViewController else {
            fatalError("Can't get SearchResultsViewController")
        }
        
        searchResultController.delegate = self
        
        searchController = UISearchController(searchResultsController: searchResultController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = String.adamantLocalized.chatList.searchPlaceholder
        definesPresentationContext = true
        
        if #available(iOS 11.0, *) {
            searchController.obscuresBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = true
            navigationItem.searchController = searchController
        } else {
            searchController.dimsBackgroundDuringPresentation = false
        
            tableView.tableHeaderView = self.searchController!.searchBar
            searchController!.searchBar.sizeToFit()
        }
        
        // MARK: Login/Logout
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.initFetchedRequestControllers(provider: self?.chatsProvider)
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.initFetchedRequestControllers(provider: nil)
        }
        
        // MARK: Busy Indicator
        busyIndicatorLabel.text = String.adamantLocalized.chatList.syncingChats
        
        busyIndicatorView.layer.cornerRadius = 14
        busyIndicatorView.clipsToBounds = true
        
        isBusy = !chatsProvider.isInitiallySynced
        if !isBusy {
            setIsBusy(false, animated: false)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantChatsProvider.initiallySyncedChanged, object: chatsProvider, queue: OperationQueue.main) { [weak self] notification in
            if let synced = notification.userInfo?[AdamantUserInfoKey.ChatProvider.initiallySynced] as? Bool {
                self?.didLoadedMessages?()
                self?.setIsBusy(!synced)
            } else if let synced = self?.chatsProvider.isInitiallySynced {
                self?.setIsBusy(!synced)
            } else {
                self?.setIsBusy(true)
            }
        }
        
        // Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            var insets = tableView.contentInset
            if let rect = self.tabBarController?.tabBar.frame {
                insets.bottom = rect.height
            }
            
            if #available(iOS 11.0, *) { } else {
                if let rect = self.navigationController?.navigationBar.frame {
                    let y = rect.size.height + rect.origin.y
                    insets.top = y
                }
            }
            tableView.contentInset = insets
        }
    }
    
    // MARK: IB Actions
    @IBAction func newChat(sender: Any) {
        let controller = router.get(scene: AdamantScene.Chats.newChat)
        
        if let c = controller as? NewChatViewController {
            c.delegate = self
        } else if let nav = controller as? UINavigationController, let c = nav.viewControllers.last as? NewChatViewController {
            c.delegate = self
        }
        
        if let split = self.splitViewController {
            split.showDetailViewController(controller, sender: self)
        } else {
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true)
        }
    }
    
    
    // MARK: Helpers
    func chatViewController(for chatroom: Chatroom, with message: MessageTransaction? = nil, forceScrollToBottom: Bool = false) -> ChatViewController {
        guard let vc = router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
            fatalError("Can't get ChatViewController")
        }
        
        if let account = accountService.account {
            vc.account = account
        }
        
        if let message = message {
            vc.messageToShow = message
        }
        
        vc.forceScrollToBottom = forceScrollToBottom
        
        vc.hidesBottomBarWhenPushed = true
        vc.chatroom = chatroom
        vc.delegate = self
        
        return vc
    }
    
    
    /// - Parameter provider: nil to drop controllers and reset table
    private func initFetchedRequestControllers(provider: ChatsProvider?) {
        guard let provider = provider else {
            chatsController = nil
            unreadController = nil
            tableView.reloadData()
            return
        }
        
        chatsController = provider.getChatroomsController()
        unreadController = provider.getUnreadMessagesController()
        
        chatsController?.delegate = self
        unreadController?.delegate = self
        
        do {
            try chatsController?.performFetch()
            try unreadController?.performFetch()
        } catch {
            chatsController = nil
            unreadController = nil
            print("There was an error performing fetch: \(error)")
        }
        
        tableView.reloadData()
        setBadgeValue(unreadController?.fetchedObjects?.count)
    }
    
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        chatsProvider.update { [weak self] (result) in
            guard let result = result else {
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                }
                return
            }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                break
                
            case .failure(let error):
                self?.dialogService.showRichError(error: error)
            }
            
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }
    
    func setIsBusy(_ busy: Bool, animated: Bool = true) {
        isBusy = busy
        
        // MARK: 0. Check if animated.
        guard animated else {
            if !busy {
                busyBackgroundView.isHidden = true
                return
            }
            
            DispatchQueue.onMainAsync {
                self.busyBackgroundView.isHidden = false
                self.busyBackgroundView.alpha = 1.0
                self.busyIndicatorView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            
            return
        }
        
        // MARK: 1. Prepare animation and completion
        let animations: () -> Void = {
            self.busyBackgroundView.alpha = busy ? 1.0 : 0.0
            self.busyIndicatorView.transform = busy ? CGAffineTransform(scaleX: 1.0, y: 1.0) : CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        let completion: (Bool) -> Void = { completed in
            guard completed else {
                return
            }
            
            self.busyBackgroundView.isHidden = !busy
        }
        
        // MARK: 2. Initial values
        let initialValues: () -> Void = {
            self.busyBackgroundView.alpha = busy ? 0.0 : 1.0
            self.busyIndicatorView.transform = busy ? CGAffineTransform(scaleX: 1.2, y: 1.2) : CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            self.busyBackgroundView.isHidden = false
        }
        
        DispatchQueue.onMainAsync {
            initialValues()
            UIView.animate(withDuration: 0.2, animations: animations, completion: completion)
        }
    }
}


// MARK: - UITableView
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let f = chatsController?.fetchedObjects {
            return f.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let chatroom = chatsController?.object(at: indexPath) {
            let vc = chatViewController(for: chatroom)
            
            if let split = self.splitViewController {
                let chat = UINavigationController(rootViewController:vc)
                split.showDetailViewController(chat, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true)
            }
        }
    }
}


// MARK: - UITableView Cells
extension ChatListViewController {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatTableViewCell
        
        cell.accessoryType = .disclosureIndicator
        cell.accountLabel.textColor = UIColor.adamant.primary
        cell.dateLabel.textColor = UIColor.adamant.secondary
        cell.avatarImageView.tintColor = UIColor.adamant.primary
        cell.borderColor = UIColor.adamant.primary
        cell.badgeColor = UIColor.adamant.primary
        cell.lastMessageLabel.textColor = UIColor.adamant.primary
        cell.borderWidth = 1
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ChatTableViewCell, let chat = chatsController?.object(at: indexPath) {
            configureCell(cell, for: chat)
        }
    }
    
    private func configureCell(_ cell: ChatTableViewCell, for chatroom: Chatroom) {
        if let partner = chatroom.partner {
            if let title = chatroom.title {
                cell.accountLabel.text = title
            } else if let name = partner.name {
                cell.accountLabel.text = name
            } else {
                cell.accountLabel.text = partner.address
            }
            
            if let avatarName = partner.avatar, let avatar = UIImage.init(named: avatarName) {
                cell.avatarImage = avatar
                cell.avatarImageView.tintColor = UIColor.adamant.primary
            } else {
                if let address = partner.publicKey {
                    DispatchQueue.global().async {
                        let image = self.avatarService.avatar(for: address, size: 200)
                        DispatchQueue.main.async {
                            cell.avatarImage = image
                        }
                    }
                    
                    cell.avatarImageView.roundingMode = .round
                    cell.avatarImageView.clipsToBounds = true
                } else {
                    cell.avatarImage = nil
                }
                cell.borderWidth = 0
            }
        } else if let title = chatroom.title {
            cell.accountLabel.text = title
        }
        
        cell.hasUnreadMessages = chatroom.hasUnreadMessages

        if let lastTransaction = chatroom.lastTransaction {
            cell.hasUnreadMessages = lastTransaction.isUnread
            cell.lastMessageLabel.attributedText = shortDescription(for: lastTransaction)
        } else {
            cell.lastMessageLabel.text = nil
        }
                
        if let date = chatroom.updatedAt as Date?, date != Date.adamantNullDate {
            cell.dateLabel.text = date.humanizedDay()
        } else {
            cell.dateLabel.text = nil
        }
    }
}


// MARK: - NSFetchedResultsControllerDelegate
extension ChatListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == chatsController {
            tableView.beginUpdates()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        switch controller {
        case let c where c == chatsController:
            tableView.endUpdates()
            
        case let c where c == unreadController:
            setBadgeValue(controller.fetchedObjects?.count)
            
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch controller {
        // MARK: Chats controller
        case let c where c == chatsController:
            switch type {
            case .insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: .automatic)
                }
                
            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
                
            case .update:
                if let indexPath = indexPath,
                   let cell = self.tableView.cellForRow(at: indexPath) as? ChatTableViewCell,
                   let chatroom = anObject as? Chatroom {
                    configureCell(cell, for: chatroom)
                }
                
            case .move:
                if let indexPath = indexPath, let newIndexPath = newIndexPath {
                    if let cell = tableView.cellForRow(at: indexPath) as? ChatTableViewCell, let chatroom = anObject as? Chatroom {
                        configureCell(cell, for: chatroom)
                    }
                    tableView.moveRow(at: indexPath, to: newIndexPath)
                }
            @unknown default:
                break
            }
            
        // MARK: Unread controller
        case let c where c == unreadController:
            guard type == .insert else {
                break
            }
            
            if let transaction = anObject as? ChatTransaction {
                if self.view.window == nil {
                    showNotification(for: transaction)
                }
            }
            
        default:
            break
        }
    }
}


// MARK: - NewChatViewControllerDelegate
extension ChatListViewController: NewChatViewControllerDelegate {
    func newChatController(_ controller: NewChatViewController, didSelectAccount account: CoreDataAccount, preMessage: String?) {
        guard let chatroom = account.chatroom else {
            fatalError("No chatroom?")
        }
        
        if let name = account.name, let address = account.address {
            let oldName = self.addressBook.addressBook[address]
            if oldName == nil || oldName != name {
                self.addressBook.set(name: name, for: address)
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let vc = self?.chatViewController(for: chatroom) else {
                return
            }
            
            let navigator: UINavigationController
            if let nav = controller.navigationController {
                navigator = nav
            } else if let nav = self?.navigationController {
                navigator = nav
            } else {
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: true) {
                    vc.becomeFirstResponder()
                    
                    if let count = vc.chatroom?.transactions?.count, count == 0 {
                        vc.messageInputBar.inputTextView.becomeFirstResponder()
                    }
                }
                
                return
            }
            
            navigator.pushViewController(vc, animated: true)
            
            if let index = navigator.viewControllers.firstIndex(of: controller) {
                navigator.viewControllers.remove(at: index)
            }
            
            if let count = vc.chatroom?.transactions?.count, count == 0 {
                vc.messageInputBar.inputTextView.becomeFirstResponder()
            }
            
            if let preMessage = preMessage {
                vc.messageInputBar.inputTextView.text = preMessage
            }
        }
        
        // Select row after awhile
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) { [weak self] in
            if let indexPath = self?.chatsController?.indexPath(forObject: chatroom) {
                self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }
}


// MARK: - ChatViewControllerDelegate
extension ChatListViewController: ChatViewControllerDelegate {
    func preserveMessage(_ message: String, forAddress address: String) {
        preservedMessagess[address] = message
    }
    
    func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String? {
        guard let message = preservedMessagess[address] else {
            return nil
        }
        
        if thenRemoveIt {
            preservedMessagess.removeValue(forKey: address)
        }
        
        return message
    }
}


// MARK: - Working with in-app notifications
extension ChatListViewController {
    private func showNotification(for transaction: ChatTransaction) {
        // MARK: 0. Do not show notifications for initial sync
        guard chatsProvider.isInitiallySynced else {
            return
        }
        
        // MARK: 1. Show notification only for incomming transactions
        guard !transaction.silentNotification, !transaction.isOutgoing,
            let chatroom = transaction.chatroom, chatroom != presentedChatroom(), !chatroom.isHidden,
            let partner = chatroom.partner else {
            return
        }
        
        // MARK: 2. Prepare notification
        let title = partner.name ?? partner.address
        let text = shortDescription(for: transaction)
        
        let image: UIImage
        if let ava = partner.avatar, let img = UIImage(named: ava) {
            image = img
        } else {
            image = defaultAvatar
        }
        
        // MARK: 4. Show notification with tap handler
        dialogService.showNotification(title: title, message: text?.string, image: image) { [weak self] in
            DispatchQueue.main.async {
                self?.presentChatroom(chatroom)
            }
        }
    }
    
    private func presentChatroom(_ chatroom: Chatroom, with message: MessageTransaction? = nil) {
        // MARK: 1. Create and config ViewController
        let vc = chatViewController(for: chatroom, with: message)
        
        if let split = self.splitViewController, UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            let chat = UINavigationController(rootViewController:vc)
            split.showDetailViewController(chat, sender: self)
        } else {
            // MARK: 2. Config TabBarController
            let animated: Bool
            if let tabVC = tabBarController, let selectedView = tabVC.selectedViewController {
                if let navigator = self.splitViewController ?? self.navigationController, selectedView != navigator, let index = tabVC.viewControllers?.firstIndex(of: navigator) {
                    animated = false
                    tabVC.selectedIndex = index
                } else {
                    animated = true
                }
            } else {
                animated = true
            }
            
            // MARK: 3. Present ViewController
            if let nav = navigationController {
                nav.dismiss(animated: true)
                nav.popToRootViewController(animated: true)
                nav.pushViewController(vc, animated: animated)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true)
            }
        }
    }
    
    private func shortDescription(for transaction: ChatTransaction) -> NSAttributedString? {
        switch transaction {
        case let message as MessageTransaction:
            guard let text = message.message else {
                return nil
            }
            
            let raw: String
            if message.isOutgoing {
                raw = "\(String.adamantLocalized.chatList.sentMessagePrefix)\(text)"
            } else {
                raw = text
            }
            
            return markdownParser.parse(raw)
            
        case let transfer as TransferTransaction:
            if let admService = richMessageProviders[AdmWalletService.richMessageType] as? AdmWalletService {
                return markdownParser.parse(admService.shortDescription(for: transfer))
            } else {
                return nil
            }
            
        case let richMessage as RichMessageTransaction:
            let description: NSAttributedString
            
            if let type = richMessage.richType, let provider = richMessageProviders[type] {
                description = provider.shortDescription(for: richMessage)
            } else if let serialized = richMessage.serializedMessage() {
                description = NSAttributedString(string: serialized)
            } else {
                return nil
            }
            
            return description
            
            /*
            if richMessage.isOutgoing {
                let mutable = NSMutableAttributedString(attributedString: description)
                let prefix = NSAttributedString(string: String.adamantLocalized.chatList.sentMessagePrefix)
                mutable.insert(prefix, at: 0)
                return mutable.attributedSubstring(from: NSRange(location: 0, length: mutable.length))
            } else {
                return description
            }
             */
            
        default:
            return nil
        }
    }
}


// MARK: - Swipe actions
extension ChatListViewController {
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let chatroom = chatsController?.object(at: indexPath) else {
            return nil
        }
        
        var actions: [UIContextualAction] = []
        
        // More
        let more = UIContextualAction(style: .normal, title: nil) { [weak self] (_, view, completionHandler: (Bool) -> Void) in
            guard let partner = chatroom.partner, let address = partner.address else {
                completionHandler(false)
                return
            }

            let params: [AdamantAddressParam]?
            if let name = partner.name {
                params = [.label(name)]
            } else {
                params = nil
            }

            let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: params))
            
            if partner.isSystem {
                self?.dialogService.presentShareAlertFor(string: address,
                                                         types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)],
                                                         excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                         animated: true,
                                                         from: view,
                                                         completion: nil)
            } else {
                let share = UIAlertAction(title: ShareType.share.localized, style: .default) { [weak self] action in
                    self?.dialogService.presentShareAlertFor(string: address,
                                                             types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)],
                                                             excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                             animated: true, from: view,
                                                             completion: nil)
                }
                
                let rename = UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak self] action in
                    let alert = UIAlertController(title: String(format: String.adamantLocalized.chat.actionsBody, address), message: nil, preferredStyle: .alert)
                    
                    alert.addTextField { (textField) in
                        textField.placeholder = String.adamantLocalized.chat.name
                        textField.autocapitalizationType = .words
                        
                        if let name = partner.name {
                            textField.text = name
                        }
                    }
                     
                    alert.addAction(UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak alert] (_) in
                        if let textField = alert?.textFields?.first, let newName = textField.text {
                            self?.addressBook.set(name: newName, for: address)
                        }
                    })
                    
                    alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
                    alert.modalPresentationStyle = .overFullScreen
                    self?.present(alert, animated: true, completion: nil)
                }
                
                let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil)
                
                self?.dialogService?.showAlert(title: nil, message: nil, style: UIAlertController.Style.actionSheet, actions: [share, rename, cancel], from: view)
            }
            
            completionHandler(true)
        }
        
        more.image = #imageLiteral(resourceName: "swipe_more")
        more.backgroundColor = UIColor.adamant.primary
        
        // Mark as read
        if chatroom.hasUnreadMessages || (chatroom.lastTransaction?.isUnread ?? false) {
            let markAsRead = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completionHandler: (Bool) -> Void) in
                guard let chatroom = self?.chatsController?.object(at: indexPath) else {
                    completionHandler(false)
                    return
                }
                
                chatroom.markAsReaded()
                try? chatroom.managedObjectContext?.save()
                completionHandler(true)
            }
            
            markAsRead.image = #imageLiteral(resourceName: "swipe_mark-as-read")
            markAsRead.backgroundColor = UIColor.adamant.primary
            
            actions = [markAsRead, more]
        } else {
            actions = [more]
        }
        
        let block = UIContextualAction(style: .destructive, title: "Block") { [weak self] (action, view, completionHandler) in
            guard let chatroom = self?.chatsController?.object(at: indexPath), let address = chatroom.partner?.address else {
                completionHandler(false)
                return
            }
            
            self?.dialogService.showAlert(title: String.adamantLocalized.chatList.blockUser, message: nil, style: .alert, actions: [
                    AdamantAlertAction(title: String.adamantLocalized.alert.ok, style: .destructive, handler: {
                    self?.chatsProvider.blockChat(with: address)
                    
                    chatroom.isHidden = true
                    try? chatroom.managedObjectContext?.save()
                    
                    completionHandler(true)
                }),
                AdamantAlertAction(title: String.adamantLocalized.alert.cancel, style: .default, handler: {
                    completionHandler(false)
                })], from: nil)
        }
        block.image = #imageLiteral(resourceName: "swipe_block")
        
        actions.append(block)
        
        return UISwipeActionsConfiguration(actions: actions)
    }
}


// MARK: - Tools
extension ChatListViewController {
    /// TabBar item badge
    func setBadgeValue(_ value: Int?) {
        let item: UITabBarItem
        if let i = navigationController?.tabBarItem {
            item = i
        } else {
            item = tabBarItem
        }
        
        if let value = value, value > 0 {
            item.badgeValue = String(value)
            notificationsService.setBadge(number: value)
        } else {
            item.badgeValue = nil
            notificationsService.setBadge(number: nil)
        }
    }
    
    /// Current chat
    func presentedChatroom() -> Chatroom? {
        guard let vc = navigationController?.visibleViewController as? ChatViewController else {
            return nil
        }
        
        return vc.chatroom
    }
}

// MARK: Search

extension ChatListViewController: UISearchBarDelegate, UISearchResultsUpdating, SearchResultDelegate {
    @objc
    func beginSearch() {
        searchController.searchBar.becomeFirstResponder()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let vc = searchController.searchResultsController as? SearchResultsViewController, let searchString = searchController.searchBar.text else {
            return
        }
        
        let contacts = chatsController?.fetchedObjects?.filter { (chatroom) -> Bool in
            guard let partner = chatroom.partner, !partner.isSystem else {
                return false
            }
            
            if let address = partner.address {
                if let name = self.addressBook.addressBook[address] {
                    return name.localizedCaseInsensitiveContains(searchString) || address.localizedCaseInsensitiveContains(searchString)
                }
                return address.localizedCaseInsensitiveContains(searchString)
            }
            
            return false
        }
        
        let messages = chatsProvider.getMessages(containing: searchString, in: nil)
        
        vc.updateResult(contacts: contacts, messages: messages, searchText: searchString)
    }
    
    func didSelected(_ message: MessageTransaction) {
        guard let chatroom = message.chatroom else {
            dialogService.showError(withMessage: "Error getting chatroom in SearchController result. Please, report an error", error: nil)
            searchController.dismiss(animated: true, completion: nil)
            return
        }
        
        searchController.dismiss(animated: true) { [weak self] in
            guard let presenter = self, let tableView = presenter.tableView else {
                return
            }
            
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            if let indexPath = self?.chatsController?.indexPath(forObject: chatroom) {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            
            presenter.presentChatroom(chatroom, with: message)
        }
    }
    
    func didSelected(_ chatroom: Chatroom) {
        searchController.dismiss(animated: true) { [weak self] in
            guard let presenter = self, let tableView = presenter.tableView else {
                return
            }
            
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            if let indexPath = self?.chatsController?.indexPath(forObject: chatroom) {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            
            presenter.presentChatroom(chatroom)
        }
    }
}

// MARK: Keyboard
extension ChatListViewController {
    @objc private func keyboardWillShow(notification: Notification) {
        guard !didShow else { return }
        didShow = true
        
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else {
            return
        }
        
        originalInsets = tableView.contentInset
        
        var contentInsets = tableView.contentInset
        
        if let tabBarHeight = tabBarController?.tabBar.bounds.height {
            contentInsets.bottom = frame.cgRectValue.size.height - tabBarHeight
        } else {
            contentInsets.bottom = frame.cgRectValue.size.height
        }
        
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        guard didShow else { return }
        didShow = false
        
        if let insets = originalInsets {
            tableView.contentInset = insets
            tableView.scrollIndicatorInsets = insets
        } else {
            var contentInsets = tableView.contentInset
            contentInsets.bottom = 0.0
            tableView.contentInset = contentInsets
            tableView.scrollIndicatorInsets = contentInsets
        }
    }
}
