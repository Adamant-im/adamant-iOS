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
import MessageKit
import Combine

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

class ChatListViewController: KeyboardObservingViewController {
    typealias SpinnerCell = TableCellWrapper<SpinnerView>
    
    let cellIdentifier = "cell"
    let loadingCellIdentifier = "loadingCell"
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
    var searchController: UISearchController?
    
    private var preservedMessagess = [String:String]()
    
    let defaultAvatar = #imageLiteral(resourceName: "avatar-chat-placeholder")
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.adamant.primary
        return refreshControl
    }()
    
    private lazy var markdownParser: MarkdownParser = {
        let parser = MarkdownParser(
            font: UIFont.systemFont(ofSize: ChatTableViewCell.shortDescriptionTextSize),
            color: .adamant.primary,
            enabledElements: [
                .header,
                .list,
                .quote,
                .bold,
                .italic,
                .strikethrough,
                .automaticLink
            ],
            customElements: [
                MarkdownSimpleAdm(),
                MarkdownLinkAdm(),
                MarkdownAdvancedAdm(
                    font: .adamantChatDefault,
                    color: .adamant.active
                ),
                MarkdownCodeAdamant(
                    font: .adamantCodeDefault,
                    textHighlightColor: .adamant.codeBlockText,
                    textBackgroundColor: .adamant.codeBlock
                )
            ]
        )
        
        return parser
    }()
    
    private lazy var updatingIndicatorView: UpdatingIndicatorView = {
        let view = UpdatingIndicatorView(title: String.adamantLocalized.chatList.title)
        return view
    }()
    
    private var defaultSeparatorInstets: UIEdgeInsets?
    
    // MARK: Busy indicator
    
    @IBOutlet weak var busyBackgroundView: UIView!
    @IBOutlet weak var busyIndicatorView: UIView!
    @IBOutlet weak var busyIndicatorLabel: UILabel!
    
    private(set) var isBusy: Bool = true
    private var lastSystemChatPositionRow: Int?
    
    private var onMessagesLoadedActions = [() -> Void]()
    private var areMessagesLoaded = false
    
    // MARK: Tasks
    
    private var loadNewChatTask: Task<(), Never>?
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        
        setupTableView()
        
        if self.accountService.account != nil {
            initFetchedRequestControllers(provider: chatsProvider)
        }
        
        setupSearchController()
        
        // MARK: Busy Indicator
        busyIndicatorLabel.text = String.adamantLocalized.chatList.syncingChats
        
        busyIndicatorView.layer.cornerRadius = 14
        busyIndicatorView.clipsToBounds = true
        
        addObservers()        
        setColors()
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
            tableView.contentInset = insets
        }
    }
    
    // MARK: Navigation controller
    
    private func setupNavigationController() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.titleView = updatingIndicatorView
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat)),
            UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(beginSearch))
        ]
    }
    
    // MARK: Search controller
    
    private func setupSearchController() {
        Task {
            isBusy = await !chatsProvider.isInitiallySynced
            if !isBusy {
                setIsBusy(false, animated: false)
            }
            
            loadNewChatTask?.cancel()
            
            guard let searchResultController = router.get(scene: AdamantScene.Chats.searchResults) as? SearchResultsViewController else {
                fatalError("Can't get SearchResultsViewController")
            }
            
            searchResultController.delegate = self
            
            searchController = UISearchController(searchResultsController: searchResultController)
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.delegate = self
            searchController?.searchBar.placeholder = String.adamantLocalized.chatList.searchPlaceholder
            definesPresentationContext = true
            
            searchController?.obscuresBackgroundDuringPresentation = false
            searchController?.hidesNavigationBarDuringPresentation = true
            navigationItem.searchController = searchController
        }
    }
    
    // MARK: TableView
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.register(SpinnerCell.self, forCellReuseIdentifier: loadingCellIdentifier)
        tableView.refreshControl = refreshControl
        tableView.backgroundColor = .clear
        tableView.tableHeaderView = UIView()
    }
    
    // MARK: Add Observers
    
    private func addObservers() {
        // Login/Logout
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.initFetchedRequestControllers(provider: self?.chatsProvider)
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.initFetchedRequestControllers(provider: nil)
                self?.areMessagesLoaded = false
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantChatsProvider.initiallySyncedChanged, object: nil)
            .receive(on: OperationQueue.main)
            .sink { notification in
                Task { [weak self] in
                    await self?.handleInitiallySyncedNotification(notification)
                }
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantTransfersProvider.stateChanged, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] notification in self?.animateUpdateIfNeeded(notification) }
            .store(in: &subscriptions)
        
    }
    
    private func animateUpdateIfNeeded(_ notification: Notification) {
        guard let prevState = notification.userInfo?[AdamantUserInfoKey.TransfersProvider.prevState] as? State,
              let newState = notification.userInfo?[AdamantUserInfoKey.TransfersProvider.newState] as? State
        else {
            return
        }
        
        if case .updating = prevState {
            updatingIndicatorView.stopAnimate()
        }
        
        if case .updating = newState {
            updatingIndicatorView.startAnimate()
        }
    }
    
    private func updateChats() {
        guard accountService.account?.address != nil,
              accountService.keypair?.privateKey != nil
        else {
            return
        }
        
        self.handleRefresh(self.refreshControl)
    }
    
    @MainActor private func handleInitiallySyncedNotification(_ notification: Notification) async {
        guard
            let userInfo = notification.userInfo,
            let synced = userInfo[AdamantUserInfoKey.ChatProvider.initiallySynced] as? Bool
        else {
            let synced = await chatsProvider.isInitiallySynced
            setIsBusy(!synced)
            return
        }
        
        areMessagesLoaded = true
        performOnMessagesLoadedActions()
        setIsBusy(!synced)
        tableView.reloadData()
    }
    
    // MARK: IB Actions
    @IBAction func newChat(sender: Any) {
        let controller = router.get(scene: AdamantScene.Chats.newChat)
        
        if let c = controller as? NewChatViewController {
            c.delegate = self
        }
        
        if let split = splitViewController {
            let nav = UINavigationController(rootViewController: controller)
            split.showDetailViewController(nav, sender: self)
        } else {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: Helpers
    func chatViewController(for chatroom: Chatroom, with messageId: String? = nil) -> ChatViewController {
        guard let vc = router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
            fatalError("Can't get ChatViewController")
        }
        
        vc.hidesBottomBarWhenPushed = true
        vc.viewModel.setup(
            account: accountService.account,
            chatroom: chatroom,
            messageIdToShow: messageId,
            preservationDelegate: self
        )

        return vc
    }
    
    /// - Parameter provider: nil to drop controllers and reset table
    @MainActor
    private func initFetchedRequestControllers(provider: ChatsProvider?) {
        Task {
            guard let provider = provider else {
                chatsController = nil
                unreadController = nil
                tableView.reloadData()
                return
            }
            
            chatsController = await provider.getChatroomsController()
            unreadController = await provider.getUnreadMessagesController()
            
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
    }
    
    @MainActor
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        Task {
            let result = await chatsProvider.update(notifyState: true)
            
            guard let result = result else {
                refreshControl.endRefreshing()
                return
            }
            
            switch result {
            case .success:
                tableView.reloadData()
                
            case .failure(let error):
                dialogService.showRichError(error: error)
            }
            
            refreshControl.endRefreshing()
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
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.backgroundColor
    }
}

// MARK: - UITableView
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let f = chatsController?.fetchedObjects {
            if f.count > 0 {
                return isBusy ? f.count + 1 : f.count
            }
            return f.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isBusy,
           indexPath.row == lastSystemChatPositionRow,
           let cell = tableView.cellForRow(at: indexPath),
           cell is SpinnerCell {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        let nIndexPath = chatControllerIndexPath(tableViewIndexPath: indexPath)
        if let chatroom = chatsController?.fetchedObjects?[safe: nIndexPath.row] {
            let vc = chatViewController(for: chatroom)
            vc.hidesBottomBarWhenPushed = true
            
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
        if isBusy && indexPath.row == lastSystemChatPositionRow {
            let cell = tableView.dequeueReusableCell(withIdentifier: loadingCellIdentifier, for: indexPath) as! SpinnerCell
            cell.wrappedView.startAnimating()
            return cell
        }
        
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
        if isBusy,
           indexPath.row == lastSystemChatPositionRow,
           let cell = cell as? SpinnerCell {
            configureCell(cell)
        } else if let cell = cell as? ChatTableViewCell {
            let nIndexPath = chatControllerIndexPath(tableViewIndexPath: indexPath)
            if let chat = chatsController?.fetchedObjects?[safe: nIndexPath.row] {
                configureCell(cell, for: chat)
            }
            if isBusy,
               indexPath.row == (lastSystemChatPositionRow ?? 0) - 1 {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            } else {
                if let defaultSeparatorInstets = defaultSeparatorInstets {
                    cell.separatorInset = defaultSeparatorInstets
                } else {
                    defaultSeparatorInstets = cell.separatorInset
                }
            }
        }
        
        Task { @MainActor in
            guard let roomsLoadedCount = await chatsProvider.roomsLoadedCount,
                  let roomsMaxCount = await chatsProvider.roomsMaxCount,
                  roomsLoadedCount < roomsMaxCount,
                  roomsMaxCount > 0,
                  !isBusy,
                  tableView.numberOfRows(inSection: .zero) - indexPath.row < 3
            else {
                return
            }
            
            isBusy = true
            insertReloadRow()
            loadNewChats(offset: roomsLoadedCount)
        }
    }
    
    private func configureCell(_ cell: SpinnerCell) {
        cell.wrappedView.startAnimating()
        cell.backgroundColor = .clear
    }
    
    private func configureCell(_ cell: ChatTableViewCell, for chatroom: Chatroom) {
        cell.backgroundColor = .clear
        if let partner = chatroom.partner {
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
        }
        
        cell.accountLabel.text = chatroom.getName(addressBookService: addressBook)
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
    
    private func insertReloadRow() {
        lastSystemChatPositionRow = getBottomSystemChatIndex()
        tableView.reloadData()
    }
    
    @MainActor
    private func loadNewChats(offset: Int) {
        loadNewChatTask = Task {
            await chatsProvider.getChatRooms(offset: offset)
            isBusy = false
            tableView.reloadData()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ChatListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if isBusy { return }
        if controller == chatsController {
            tableView.beginUpdates()
            updatingIndicatorView.startAnimate()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if isBusy { return }
        switch controller {
        case let c where c == chatsController:
            tableView.endUpdates()
            updatingIndicatorView.stopAnimate()
            
        case let c where c == unreadController:
            setBadgeValue(controller.fetchedObjects?.count)
            
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if isBusy { return }
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
            if let _ = anObject as? TransferTransaction {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    NotificationCenter.default.post(name: .AdamantAccountService.forceUpdateBalance, object: nil)
                }
            }
        default:
            break
        }
    }
}

// MARK: - NewChatViewControllerDelegate
extension ChatListViewController: NewChatViewControllerDelegate {
    func newChatController(
        didSelectAccount account: CoreDataAccount,
        preMessage: String?,
        name: String?
    ) {
        guard let chatroom = account.chatroom else {
            fatalError("No chatroom?")
        }
        
        if let name = name,
           let address = account.address,
           addressBook.getName(for: address) == nil {
            account.name = name
            chatroom.title = name
            Task {
                await self.addressBook.set(name: name, for: address)
            }
        }
        
        DispatchQueue.main.async { [self] in
            let vc = chatViewController(for: chatroom)
            
            if let split = splitViewController {
                let nav = UINavigationController(rootViewController: vc)
                split.showDetailViewController(nav, sender: self)
                vc.becomeFirstResponder()
                
                if let count = vc.viewModel.chatroom?.transactions?.count, count == 0 {
                    vc.messageInputBar.inputTextView.becomeFirstResponder()
                }
            } else {
                navigationController?.setViewControllers([self, vc], animated: true)
            }
            
            if let count = vc.viewModel.chatroom?.transactions?.count, count == 0 {
                vc.messageInputBar.inputTextView.becomeFirstResponder()
            }
            
            if let preMessage = preMessage {
                vc.viewModel.inputText = preMessage
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

// MARK: - ChatPreservationDelegate

extension ChatListViewController: ChatPreservationDelegate {
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
        Task {
            // MARK: 0. Do not show notifications for initial sync
            guard await chatsProvider.isInitiallySynced else {
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
            dialogService.showNotification(title: title?.checkAndReplaceSystemWallets(), message: text?.string, image: image) { [weak self] in
                DispatchQueue.main.async {
                    self?.presentChatroom(chatroom)
                }
            }
        }
    }
    
    private func presentChatroom(_ chatroom: Chatroom, with message: MessageTransaction? = nil) {
        // MARK: 1. Create and config ViewController
        let vc = chatViewController(for: chatroom, with: message?.transactionId)
        
        if let split = self.splitViewController, UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            let chat = UINavigationController(rootViewController:vc)
            split.showDetailViewController(chat, sender: self)
            tabBarController?.selectedIndex = .zero
        } else {
            // MARK: 2. Config TabBarController
            let animated = tabBarController?.selectedIndex == .zero
            tabBarController?.selectedIndex = .zero
            
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
            
            let attributesText = markdownParser.parse(raw).resolveLinkColor()
            
            return attributesText
            
        case let transfer as TransferTransaction:
            if let admService = richMessageProviders[AdmWalletService.richMessageType] as? AdmWalletService {
                return markdownParser.parse(admService.shortDescription(for: transfer))
            } else {
                return nil
            }
            
        case let richMessage as RichMessageTransaction:
            if let type = richMessage.richType,
               let provider = richMessageProviders[type] {
                return provider.shortDescription(for: richMessage)
            }
            
            if richMessage.isReply,
               let content = richMessage.richContent,
               let text = content[RichContentKeys.reply.replyMessage] as? String {
                
                let prefix = richMessage.isOutgoing
                ? "\(String.adamantLocalized.chatList.sentMessagePrefix)"
                : ""
                
                let replyImageAttachment = NSTextAttachment()
                
                replyImageAttachment.image = UIImage(
                    systemName: "arrowshape.turn.up.left"
                )?.withTintColor(.adamant.primary)
                
                replyImageAttachment.bounds = CGRect(
                    x: .zero,
                    y: -3,
                    width: 23,
                    height: 20
                )
                
                let imageString = NSAttributedString(attachment: replyImageAttachment)
                
                let markDownText = markdownParser.parse("  \(text)").resolveLinkColor()
                
                let fullString = NSMutableAttributedString(string: prefix)
                fullString.append(imageString)
                fullString.append(markDownText)
                
                return fullString
            }
            
            if richMessage.isReact,
               let content = richMessage.richContent,
               let reaction = content[RichContentKeys.react.react_message] as? String {
                let prefix = richMessage.isOutgoing
                ? "\(String.adamantLocalized.chatList.sentMessagePrefix)"
                : ""
                
                let text = reaction.isEmpty
                ? NSMutableAttributedString(string: "\(prefix)\(String.adamantLocalized.notifications.removedReaction) \(reaction)")
                : NSMutableAttributedString(string: "\(prefix)\(String.adamantLocalized.notifications.reacted) \(reaction)")
                
                return text
            }
            
            if let serialized = richMessage.serializedMessage() {
                return NSAttributedString(string: serialized)
            }
            
            return nil
            
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
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let chatroom = chatsController?.fetchedObjects?[safe: indexPath.row] else {
            return nil
        }
        
        var actions: [UIContextualAction] = []
        
        // More
        let more = makeMooreContextualAction(for: chatroom)
        actions.append(more)
        
        // Mark as read
        if chatroom.hasUnreadMessages || (chatroom.lastTransaction?.isUnread ?? false) {
            let markAsRead = makeMarkAsReadContextualAction(for: chatroom)
            actions.append(markAsRead)
        }
        
        // Block
        let block = makeBlockContextualAction(for: chatroom)
        actions.append(block)
        
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    private func blockChat(with address: String, for chatroom: Chatroom?) {
        Task {
            chatroom?.isHidden = true
            try? chatroom?.managedObjectContext?.save()
            await chatsProvider.blockChat(with: address)
        }
    }
    
    private func makeBlockContextualAction(for chatroom: Chatroom) -> UIContextualAction {
        let block = UIContextualAction(
            style: .destructive,
            title: .adamantLocalized.chat.block
        ) { [weak self] (_, _, completionHandler) in
            guard let address = chatroom.partner?.address else {
                completionHandler(false)
                return
            }
            
            self?.dialogService.showAlert(
                title: String.adamantLocalized.chatList.blockUser,
                message: nil,
                style: .alert,
                actions: [
                    .init(
                        title: .adamantLocalized.alert.ok,
                        style: .destructive,
                        handler: {
                            self?.blockChat(with: address, for: chatroom)
                            completionHandler(true)
                        }
                    ),
                    .init(
                        title: .adamantLocalized.alert.cancel,
                        style: .default,
                        handler: { completionHandler(false) }
                    )
                ],
                from: nil
            )
        }
        
        block.image = #imageLiteral(resourceName: "swipe_block")
        
        return block
    }
    
    private func makeMarkAsReadContextualAction(for chatroom: Chatroom) -> UIContextualAction {
        let markAsRead = UIContextualAction(
            style: .normal,
            title: nil
        ) { (_, _, completionHandler) in
            chatroom.markAsReaded()
            try? chatroom.managedObjectContext?.save()
            completionHandler(true)
        }
        
        markAsRead.image = #imageLiteral(resourceName: "swipe_mark-as-read")
        markAsRead.backgroundColor = UIColor.adamant.primary
        return markAsRead
    }
    
    private func makeMooreContextualAction(for chatroom: Chatroom) -> UIContextualAction {
        let more = UIContextualAction(
            style: .normal,
            title: nil
        ) { [weak self] (_, view, completionHandler) in
            guard let self = self,
                  let partner = chatroom.partner,
                  let address = partner.address
            else {
                completionHandler(false)
                return
            }

            let params: [AdamantAddressParam]?
            if let name = partner.name {
                params = [.label(name)]
            } else {
                params = nil
            }

            let encodedAddress = AdamantUriTools.encode(
                request: AdamantUri.address(
                    address: address,
                    params: params
                )
            )
            
            guard !partner.isSystem else {
                self.dialogService.presentShareAlertFor(
                    string: address,
                    types: [
                        .copyToPasteboard,
                        .share,
                            .generateQr(
                                encodedContent: encodedAddress,
                                sharingTip: address,
                                withLogo: true
                            )
                    ],
                    excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                    animated: true,
                    from: view,
                    completion: nil
                )
                
                completionHandler(true)
                return
            }
            
            let share = self.makeShareAction(
                for: address,
                encodedAddress: encodedAddress,
                sender: view
            )
            
            let rename = self.makeRenameAction(for: address)
            let cancel = self.makeCancelAction()
            
            self.dialogService?.showAlert(
                title: nil,
                message: nil,
                style: UIAlertController.Style.actionSheet,
                actions: [share, rename, cancel],
                from: view
            )
            
            completionHandler(true)
        }
        
        more.image = #imageLiteral(resourceName: "swipe_more")
        more.backgroundColor = .adamant.secondary
        return more
    }
    
    private func makeShareAction(
        for address: String,
        encodedAddress: String,
        sender: UIView
    ) -> UIAlertAction {
        .init(
            title: ShareType.share.localized,
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            
            self.dialogService.presentShareAlertFor(
                string: address,
                types: [
                    .copyToPasteboard,
                    .share,
                    .generateQr(
                        encodedContent: encodedAddress,
                        sharingTip: address,
                        withLogo: true
                    )
                ],
                excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                animated: true,
                from: sender,
                completion: nil
            )
        }
    }
    
    private func makeRenameAction(for address: String) -> UIAlertAction {
        .init(
            title: .adamantLocalized.chat.rename,
            style: .default
        ) { [weak self] _ in
            guard let alert = self?.makeRenameAlert(for: address) else { return }
            self?.dialogService.present(alert, animated: true) {
                self?.dialogService.selectAllTextFields(in: alert)
            }
        }
    }
    
    private func makeRenameAlert(for address: String) -> UIAlertController? {
        let alert = UIAlertController(
            title: .init(format: .adamantLocalized.chat.actionsBody, address),
            message: nil,
            preferredStyle: .alert
        )
        
        alert.addTextField { [weak self] textField in
            textField.placeholder = .adamantLocalized.chat.name
            textField.autocapitalizationType = .words
            textField.text = self?.addressBook.getName(for: address)
        }
        
        let renameAction = UIAlertAction(
            title: .adamantLocalized.chat.rename,
            style: .default
        ) { [weak self] _ in
            guard
                let textField = alert.textFields?.first,
                let newName = textField.text
            else { return }
            
            Task {
                await self?.addressBook.set(name: newName, for: address)
            }
        }
        
        alert.addAction(renameAction)
        alert.addAction(makeCancelAction())
        alert.modalPresentationStyle = .overFullScreen
        return alert
    }
    
    private func makeCancelAction() -> UIAlertAction {
        .init(title: .adamantLocalized.alert.cancel, style: .cancel, handler: nil)
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
        
        return vc.viewModel.chatroom
    }
    
    /// First system botoom chat index
    func getBottomSystemChatIndex() -> Int {
        var index = 0
        try? chatsController?.performFetch()
        chatsController?.fetchedObjects?.enumerated().forEach({ (i, room) in
            guard index == 0,
                  let date = room.updatedAt as? Date,
                  date == Date.adamantNullDate
            else {
                return
            }
            index = i
        })

        return index
    }
    
    func selectChatroomRow(chatroom: Chatroom) {
        guard let chatsControllerIndexPath = chatsController?.indexPath(forObject: chatroom) else { return }
        let tableViewIndexPath = tableViewIndexPath(chatControllerIndexPath: chatsControllerIndexPath)
        tableView.selectRow(at: tableViewIndexPath, animated: true, scrollPosition: .none)
        tableView.scrollToRow(at: tableViewIndexPath, at: .top, animated: true)
    }
    
    func performOnMessagesLoaded(action: @escaping () -> Void) {
        onMessagesLoadedActions.append(action)
        
        guard areMessagesLoaded else { return }
        performOnMessagesLoadedActions()
    }
    
    private func chatControllerIndexPath(tableViewIndexPath: IndexPath) -> IndexPath {
        isBusy && tableViewIndexPath.row >= (lastSystemChatPositionRow ?? 0)
            ? IndexPath(row: tableViewIndexPath.row - 1, section: 0)
            : tableViewIndexPath
    }
    
    private func tableViewIndexPath(chatControllerIndexPath: IndexPath) -> IndexPath {
        isBusy && chatControllerIndexPath.row == (lastSystemChatPositionRow ?? 0)
            ? IndexPath(row: chatControllerIndexPath.row + 1, section: 0)
            : chatControllerIndexPath
    }
    
    private func performOnMessagesLoadedActions() {
        onMessagesLoadedActions.forEach { $0() }
        onMessagesLoadedActions = []
    }
    
    @objc private func showDefaultScreen() {
        splitViewController?.showDetailViewController(WelcomeViewController(), sender: self)
    }
}

// MARK: Search

extension ChatListViewController: UISearchBarDelegate, UISearchResultsUpdating, SearchResultDelegate {
    @objc
    func beginSearch() {
        searchController?.searchBar.becomeFirstResponder()
    }
    
    @MainActor
    func updateSearchResults(for searchController: UISearchController) {
        guard let vc = searchController.searchResultsController as? SearchResultsViewController, let searchString = searchController.searchBar.text else {
            return
        }
        
        let contacts = chatsController?.fetchedObjects?.filter { (chatroom) -> Bool in
            guard let partner = chatroom.partner, !partner.isSystem else {
                return false
            }
            
            if let address = partner.address {
                if let name = self.addressBook.getName(for: address) {
                    return name.localizedCaseInsensitiveContains(searchString) || address.localizedCaseInsensitiveContains(searchString)
                }
                return address.localizedCaseInsensitiveContains(searchString)
            }
            
            return false
        }
        
        Task {
            let messages = await chatsProvider.getMessages(containing: searchString, in: nil)
            
            vc.updateResult(contacts: contacts, messages: messages, searchText: searchString)
        }
    }
    
    func didSelected(_ message: MessageTransaction) {
        guard let chatroom = message.chatroom else {
            dialogService.showError(withMessage: "Error getting chatroom in SearchController result. Please, report an error", supportEmail: true, error: nil)
            searchController?.dismiss(animated: true, completion: nil)
            return
        }
        
        searchController?.dismiss(animated: true) { [weak self] in
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
        searchController?.dismiss(animated: true) { [weak self] in
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
    
    func didSelected(_ account: CoreDataAccount) {
        account.chatroom?.isForcedVisible = true
        newChatController(didSelectAccount: account, preMessage: nil, name: nil)
    }
}

// MARK: Mac OS HotKeys

extension ChatListViewController {
    override var keyCommands: [UIKeyCommand]? {
        let commands = [
            UIKeyCommand(
                input: UIKeyCommand.inputEscape,
                modifierFlags: [],
                action: #selector(showDefaultScreen)
            )
        ]
        commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
        return commands
    }
}
