//
//  ChatListViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
@preconcurrency import CoreData
import MarkdownKit
import MessageKit
import Combine
import CommonKit

extension String.adamant {
    enum chatList {
        static var title: String {
            String.localized("ChatListPage.Title", comment: "ChatList: scene title")
        }
        static var sentMessagePrefix: String {
            String.localized("ChatListPage.SentMessagePrefix", comment: "ChatList: outgoing message prefix")
        }
        static var syncingChats: String {
            String.localized("ChatListPage.SyncingChats", comment: "ChatList: First syncronization is in progress")
        }
        static var searchPlaceholder: String {
            String.localized("ChatListPage.SearchBar.Placeholder", comment: "ChatList: SearchBar placeholder text")
        }
        static var blockUser: String {
            String.localized("Chats.BlockUser", comment: "Block this user?")
        }
        static var removedReaction: String {
            String.localized("ChatListPage.RemovedReaction", comment: "ChatList: Removed Reaction?")
        }
        static var reacted: String {
            String.localized("ChatListPage.Reacted", comment: "ChatList: Reacted")
        }
    }
}

final class ChatListViewController: KeyboardObservingViewController {
    typealias SpinnerCell = TableCellWrapper<SpinnerView>
    
    let cellIdentifier = "cell"
    let loadingCellIdentifier = "loadingCell"
    let cellHeight: CGFloat = 76.0
    
    // MARK: Dependencies
    
    private let accountService: AccountService
    private let chatsProvider: ChatsProvider
    private let transfersProvider: TransfersProvider
    private let screensFactory: ScreensFactory
    private let notificationsService: NotificationsService
    private let dialogService: DialogService
    private let addressBook: AddressBookService
    private let avatarService: AvatarService
    private let walletServiceCompose: WalletServiceCompose
    
    // MARK: IBOutlet
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newChatButton: UIBarButtonItem!
    
    private lazy var scrollUpButton = ChatScrollButton(position: .up)

    // MARK: Properties
    var chatsController: NSFetchedResultsController<Chatroom>?
    var unreadController: NSFetchedResultsController<ChatTransaction>?
    var searchController: UISearchController?
    
    private var transactionsRequiringBalanceUpdate: [String] = []
    
    let defaultAvatar = UIImage.asset(named: "avatar-chat-placeholder") ?? .init()
    
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
                ),
                MarkdownFileRaw(emoji: "📸", font: .adamantChatFileRawDefault),
                MarkdownFileRaw(emoji: "📄", font: .adamantChatFileRawDefault)
            ]
        )
        
        return parser
    }()
    
    private lazy var updatingIndicatorView: UpdatingIndicatorView = {
        let view = UpdatingIndicatorView(title: String.adamant.chatList.title)
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
    private var lastDatesUpdate: Date = Date()
    
    // MARK: Tasks
    
    private var loadNewChatTask: Task<(), Never>?
    private var subscriptions = Set<AnyCancellable>()
    
    // MARK: Init
    
    init(
        accountService: AccountService,
        chatsProvider: ChatsProvider,
        transfersProvider: TransfersProvider,
        screensFactory: ScreensFactory,
        notificationsService: NotificationsService,
        dialogService: DialogService,
        addressBook: AddressBookService,
        avatarService: AvatarService,
        walletServiceCompose: WalletServiceCompose
    ) {
        self.accountService = accountService
        self.chatsProvider = chatsProvider
        self.transfersProvider = transfersProvider
        self.screensFactory = screensFactory
        self.notificationsService = notificationsService
        self.dialogService = dialogService
        self.addressBook = addressBook
        self.avatarService = avatarService
        self.walletServiceCompose = walletServiceCompose
        
        super.init(nibName: "ChatListViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        busyIndicatorLabel.text = String.adamant.chatList.syncingChats
        
        busyIndicatorView.layer.cornerRadius = 14
        busyIndicatorView.clipsToBounds = true
        
        configureScrollUpButton()
        addObservers()
        setColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
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
            let searchResultController = screensFactory.makeSearchResults()
            searchResultController.delegate = self
            
            searchController = UISearchController(searchResultsController: searchResultController)
            searchController?.searchResultsUpdater = self
            searchController?.searchBar.delegate = self
            searchController?.searchBar.placeholder = String.adamant.chatList.searchPlaceholder
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
    
    func configureScrollUpButton() {
        view.addSubview(scrollUpButton)
        
        scrollUpButton.isHidden = true
        
        scrollUpButton.action = { [weak self] in
            self?.tableView.scrollToRow(at: IndexPath(row: .zero, section: .zero), at: .top, animated: true)
        }
        
        scrollUpButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.size.equalTo(30)
        }
    }
    
    // MARK: Add Observers
    
    private func addObservers() {
        // Login/Logout
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.initFetchedRequestControllers(provider: self?.chatsProvider)
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.initFetchedRequestControllers(provider: nil)
                self?.areMessagesLoaded = false
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantChatsProvider.initiallySyncedChanged, object: nil)
            .sink { @MainActor notification in
                Task { [weak self] in
                    await self?.handleInitiallySyncedNotification(notification)
                }
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantTransfersProvider.stateChanged, object: nil)
            .sink { @MainActor [weak self] notification in self?.animateUpdateIfNeeded(notification) }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .LanguageStorageService.languageUpdated)
            .sink { @MainActor [weak self] _ in
                self?.updateUITitles()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .Storage.storageClear)
            .sink { @MainActor [weak self] _ in
                self?.closeDetailVC()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .Storage.storageProprietiesUpdated)
            .sink { @MainActor [weak self] _ in
                self?.closeDetailVC()
            }
            .store(in: &subscriptions)
    }
    
    private func closeDetailVC() {
        guard let splitVC = tabBarController?.viewControllers?.first as? UISplitViewController,
              !splitVC.isCollapsed
        else { return }
        
        splitVC.showDetailViewController(WelcomeViewController(), sender: nil)
    }
    
    private func updateUITitles() {
        updatingIndicatorView.updateTitle(title:  String.adamant.chatList.title)
        tableView.reloadData()
        searchController?.searchBar.placeholder = String.adamant.chatList.searchPlaceholder
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
            refreshDatesIfNeeded()
        }
    }
    
    /// If the user opens the app from the background and new chats are not loaded,
    /// update specific rows in the tableView to refresh the dates.
    private func refreshDatesIfNeeded() {
        guard !isBusy,
              let indexPaths = tableView.indexPathsForVisibleRows
        else {
            return
        }
        
        lastDatesUpdate = Date()
        tableView.reloadRows(at: indexPaths, with: .none)
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
        let controller = screensFactory.makeNewChat()
        controller.delegate = self
        
        if let split = splitViewController {
            let nav = UINavigationController(rootViewController: controller)
            split.showDetailViewController(nav, sender: self)
        } else {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: Helpers
    func chatViewController(
        for chatroom: Chatroom,
        with messageId: String? = nil
    ) -> ChatViewController {
        let vc = screensFactory.makeChat()
        vc.hidesBottomBarWhenPushed = true
        vc.viewModel.setup(
            account: accountService.account,
            chatroom: chatroom,
            messageIdToShow: messageId
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y + scrollView.safeAreaInsets.top
        scrollUpButton.isHidden = offsetY < cellHeight * 0.75
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
        
        cell.accessoryType = .none
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
            if let avatarName = partner.avatar, let avatar = UIImage.asset(named: avatarName) {
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
            let isUnread = chatsProvider.isUnreadChat(chatroom: chatroom)
            cell.hasUnreadMessages = isUnread
            cell.lastMessageLabel.attributedText = shortDescription(for: lastTransaction)
        } else {
            cell.lastMessageLabel.text = nil
        }
                
        if let date = chatroom.updatedAt as Date?, date != .adamantNullDate {
            cell.dateLabel.text = date.humanizedDay(useTimeFormat: true)
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
            guard let transaction = anObject as? ChatTransaction else { break }
            
            if self.view.window == nil,
               type == .insert {
                showNotification(for: transaction)
            }
            
            let shouldForceUpdate = anObject is TransferTransaction
            || anObject is RichMessageTransaction
            
            if shouldForceUpdate, type == .insert {
                transactionsRequiringBalanceUpdate.append(transaction.txId)
            }
            
            guard shouldForceUpdate,
                  let blockId = transaction.blockId,
                  !blockId.isEmpty,
                  transactionsRequiringBalanceUpdate.contains(transaction.txId)
            else {
                break
            }
            
            if let index = transactionsRequiringBalanceUpdate.firstIndex(of: transaction.txId) {
                transactionsRequiringBalanceUpdate.remove(at: index)
            }
            
            NotificationCenter.default.post(
                name: .AdamantAccountService.forceUpdateBalance,
                object: nil
            )
            
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

// MARK: - Working with in-app notifications
extension ChatListViewController {
    private func showNotification(for transaction: ChatTransaction) {
        Task {
            // MARK: 0. Do not show notifications for initial sync
            guard await chatsProvider.isInitiallySynced else {
                return
            }
            
            // MARK: 1. Show notification only for incomming transactions
            guard !transaction.silentNotification,
                  !transaction.isOutgoing,
                  let chatroom = transaction.chatroom,
                  chatroom != presentedChatroom(),
                  !chatroom.isHidden,
                  let partner = chatroom.partner,
                  let address = partner.address
            else {
                return
            }
            
            // MARK: 2. Prepare notification
            
            let name: String? = partner.name ?? addressBook.getName(for: address)
            let title = name ?? partner.address
            let text = shortDescription(for: transaction)
            
            let image: UIImage
            if let ava = partner.avatar, let img = UIImage.asset(named: ava) {
                image = img
            } else if let publicKey = partner.publicKey {
                image = avatarService.avatar(for: publicKey, size: 30)
            } else {
                image = defaultAvatar
            }
            
            // MARK: 4. Show notification with tap handler
            dialogService.showNotification(
                title: title?.checkAndReplaceSystemWallets(),
                message: text?.string,
                image: image
            ) { [weak self] in
                self?.presentChatroom(chatroom)
            }
        }
    }
    
    @MainActor
    func presentChatroom(_ chatroom: Chatroom, with message: MessageTransaction? = nil) {
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
            guard var text = message.message else {
                return nil
            }
            text = MessageProcessHelper.process(text)
            
            var raw: String
            if message.isOutgoing {
                raw = "\(String.adamant.chatList.sentMessagePrefix)\(text)"
            } else {
                raw = text
            }
            
            var attributedText = markdownParser.parse(raw).resolveLinkColor()
            attributedText = MessageProcessHelper.process(attributedText: attributedText)
            
            return attributedText
            
        case let transfer as TransferTransaction:
            if let admService = walletServiceCompose.getWallet(
                by: AdmWalletService.richMessageType
            )?.core as? AdmWalletService {
                return markdownParser.parse(admService.shortDescription(for: transfer))
            }
            
            return nil
        case let richMessage as RichMessageTransaction:
            if let type = richMessage.richType,
               let provider = walletServiceCompose.getWallet(by: type) {
                return provider.core.shortDescription(for: richMessage)
            }
            
            if richMessage.additionalType == .reply,
               let content = richMessage.richContent,
               let text = content[RichContentKeys.reply.replyMessage] as? String {
                return getRawReplyPresentation(isOutgoing: richMessage.isOutgoing, text: text)
            }
            
            if richMessage.additionalType == .reaction,
               let content = richMessage.richContent,
               let reaction = content[RichContentKeys.react.react_message] as? String {
                let prefix = richMessage.isOutgoing
                ? "\(String.adamant.chatList.sentMessagePrefix)"
                : ""
                
                let text = reaction.isEmpty
                ? NSMutableAttributedString(string: "\(prefix)\(String.adamant.chatList.removedReaction) \(reaction)")
                : NSMutableAttributedString(string: "\(prefix)\(String.adamant.chatList.reacted) \(reaction)")
                
                return text
            }
            
            if richMessage.additionalType == .reply,
               let content = richMessage.richContent,
               richMessage.isFileReply() {
                let text = FilePresentationHelper.getFilePresentationText(content)
                return getRawReplyPresentation(isOutgoing: richMessage.isOutgoing, text: text)
            }
            
            if richMessage.additionalType == .file,
               let content = richMessage.richContent {
                let prefix = richMessage.isOutgoing
                ? "\(String.adamant.chatList.sentMessagePrefix)"
                : ""
                
                let fileText = FilePresentationHelper.getFilePresentationText(content)
                
                let attributesText = markdownParser.parse(prefix + fileText).resolveLinkColor()
                
                return attributesText
            }
            
            if let serialized = richMessage.serializedMessage() {
                return NSAttributedString(string: serialized)
            }
            
            return nil
            
            /*
            if richMessage.isOutgoing {
                let mutable = NSMutableAttributedString(attributedString: description)
                let prefix = NSAttributedString(string: String.adamant.chatList.sentMessagePrefix)
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
    
    private func getRawReplyPresentation(isOutgoing: Bool, text: String) -> NSMutableAttributedString {
        let prefix = isOutgoing
        ? "\(String.adamant.chatList.sentMessagePrefix)"
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
        
        let extraSpace = isOutgoing ? "  " : ""
        let imageString = NSAttributedString(attachment: replyImageAttachment)
        
        let markDownText = markdownParser.parse("\(extraSpace)\(text)").resolveLinkColor()
        
        let fullString = NSMutableAttributedString(string: prefix)
        if isOutgoing {
            fullString.append(imageString)
        }
        fullString.append(markDownText)
        
        return MessageProcessHelper.process(attributedText: fullString)
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
        
        // Block
        let block = makeBlockContextualAction(for: chatroom)
        actions.append(block)
        
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let chatroom = chatsController?.fetchedObjects?[safe: indexPath.row] else {
            return nil
        }
        
        var actions: [UIContextualAction] = []
      
        let markAsRead = makeMarkAsReadContextualAction(for: chatroom)
        actions.append(markAsRead)
        
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
            title: .adamant.chat.block
        ) { [weak self] (_, _, completionHandler) in
            guard let address = chatroom.partner?.address else {
                completionHandler(false)
                return
            }
            
            self?.dialogService.showAlert(
                title: String.adamant.chatList.blockUser,
                message: nil,
                style: .alert,
                actions: [
                    .init(
                        title: .adamant.alert.ok,
                        style: .destructive,
                        handler: {
                            self?.blockChat(with: address, for: chatroom)
                            completionHandler(true)
                        }
                    ),
                    .init(
                        title: .adamant.alert.cancel,
                        style: .default,
                        handler: { completionHandler(false) }
                    )
                ],
                from: nil
            )
        }
        
        block.image = .asset(named: "swipe_block")?.withTintColor(.adamant.warning, renderingMode: .alwaysOriginal)
        block.backgroundColor = .adamant.swipeBlockColor
        
        return block
    }
    
    private func makeMarkAsReadContextualAction(for chatroom: Chatroom) -> UIContextualAction {
        let markAsRead = UIContextualAction(
            style: .normal,
            title: "👀"
        ) { [weak self] (_, _, completionHandler) in
            guard let self = self else { return }
            
            Task { @MainActor in
                defer {
                    completionHandler(true)
                    self.tableView.reloadData()
                }
                
                guard
                    let address = chatroom.partner?.address,
                    let lastTransaction = chatroom.lastTransaction
                else {
                    return
                }
                
                let isUnread = await self.chatsProvider.isUnreadChat(chatroom: chatroom)
                
                guard let transactions = chatroom.transactions as? Set<ChatTransaction>
                else { return }
                
                if isUnread {
                    await self.chatsProvider.setLastReadMessage(
                        height: lastTransaction.height,
                        transactions: transactions,
                        chatroom: address
                    )
                    return
                }
                
                await self.chatsProvider.setLastReadMessage(
                    height: lastTransaction.height - 1,
                    transactions: [],
                    chatroom: address
                )
            }
        }

        markAsRead.backgroundColor = UIColor.adamant.contextMenuDefaultBackgroundColor
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
            
            let closeAction: (() -> Void)? = { [completionHandler] in
                completionHandler(true)
            }
            
            let share = self.makeShareAction(
                for: address,
                encodedAddress: encodedAddress,
                sender: view,
                completion: closeAction
            )
            
            let rename = self.makeRenameAction(for: address, completion: closeAction)
            let cancel = self.makeCancelAction(completion: closeAction)
            
            self.dialogService.showAlert(
                title: nil,
                message: nil,
                style: UIAlertController.Style.actionSheet,
                actions: [share, rename, cancel],
                from: .view(view)
            )
        }
        
        more.image = .asset(named: "swipe_more")
        more.backgroundColor = .adamant.swipeMoreColor
        return more
    }
    
    private func makeShareAction(
        for address: String,
        encodedAddress: String,
        sender: UIView,
        completion: (() -> Void)? = nil
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
                completion: completion
            )
        }
    }
    
    private func makeRenameAction(
        for address: String,
        completion: (() -> Void)? = nil
    ) -> UIAlertAction {
        .init(
            title: .adamant.chat.rename,
            style: .default
        ) { [weak self] _ in
            guard let alert = self?.makeRenameAlert(for: address) else { return }
            self?.dialogService.present(alert, animated: true) {
                self?.dialogService.selectAllTextFields(in: alert)
                completion?()
            }
        }
    }
    
    private func makeRenameAlert(for address: String) -> UIAlertController? {
        let alert = UIAlertController(
            title: .init(format: .adamant.chat.actionsBody, address),
            message: nil,
            preferredStyleSafe: .alert,
            source: nil
        )
        
        alert.addTextField { [weak self] textField in
            textField.placeholder = .adamant.chat.name
            textField.autocapitalizationType = .words
            textField.text = self?.addressBook.getName(for: address)
        }
        
        let renameAction = UIAlertAction(
            title: .adamant.chat.rename,
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
    
    private func makeCancelAction(completion: (() -> Void)? = nil) -> UIAlertAction {
        .init(
            title: .adamant.alert.cancel,
            style: .cancel
        ) { _ in
            completion?()
        }
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
                  date == .adamantNullDate
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
