//
//  AdamantChatsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
@preconcurrency import CoreData
import MarkdownKit
import Combine
import CommonKit

actor AdamantChatsProvider: ChatsProvider {
    
    // MARK: Dependencies
    
    private let socketService: SocketService
    private let adamantCore: AdamantCore
    private let transactionService: ChatTransactionService
    private let walletServiceCompose: WalletServiceCompose
    
    let accountService: AccountService
    let accountsProvider: AccountsProvider
    let securedStore: SecuredStore
    let apiService: AdamantApiServiceProtocol
    let stack: CoreDataStack
    
    // MARK: Properties
    @ObservableValue private var stateNotifier: State = .empty
    var stateObserver: AnyObservable<State> { $stateNotifier.eraseToAnyPublisher() }
    
    private(set) var state: State = .empty
    private(set) var receivedLastHeight: Int64?
    private(set) var readedLastHeight: Int64?
    private let apiTransactions = 100
    private let chatTransactionsLimit = 50
    private var unconfirmedTransactions: [UInt64:NSManagedObjectID] = [:]
    private var unconfirmedTransactionsBySignature: [String] = []
    
    @MainActor private var chatPositon: [String : Double] = [:]
    private(set) var blockList: [String] = []
    private(set) var removedMessages: [String] = []
    
    @ObservableValue private var chatLoadingStatusDictionary: [String: ChatRoomLoadingStatus] = [:]
    var chatLoadingStatusPublisher: AnyObservable<[String: ChatRoomLoadingStatus]> {
        $chatLoadingStatusDictionary.eraseToAnyPublisher()
    }
    
    var chatMaxMessages: [String : Int] = [:]
    var chatLoadedMessages: [String : Int] = [:]
    private let preLoadChatsCount = 5
    private var isConnectedToTheInternet = true
    private var onConnectionToTheInternetRestoredTasks = [() -> Void]()
    
    private(set) var isInitiallySynced: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.AdamantChatsProvider.initiallySyncedChanged, object: self, userInfo: [AdamantUserInfoKey.ChatProvider.initiallySynced : isInitiallySynced])
        }
    }
    
    private let markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: UIFont.systemFontSize))
    
    private var previousAppState: UIApplication.State?
    
    private(set) var roomsMaxCount: Int?
    private(set) var roomsLoadedCount: Int?
    
    private var subscriptions = Set<AnyCancellable>()
    private let minReactionsProcent = 30
    
    // MARK: Lifecycle
    init(
        accountService: AccountService,
        apiService: AdamantApiServiceProtocol,
        socketService: SocketService,
        stack: CoreDataStack,
        adamantCore: AdamantCore,
        accountsProvider: AccountsProvider,
        transactionService: ChatTransactionService,
        securedStore: SecuredStore,
        walletServiceCompose: WalletServiceCompose
    ) {
        self.accountService = accountService
        self.apiService = apiService
        self.socketService = socketService
        self.stack = stack
        self.adamantCore = adamantCore
        self.accountsProvider = accountsProvider
        self.transactionService = transactionService
        self.securedStore = securedStore
        self.walletServiceCompose = walletServiceCompose
        
        Task {
            await setupSecuredStore()
            await addObservers()
        }
    }
    
    private func addObservers() {
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] in await self?.userLoggedInAction($0) }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in await self?.userLogOutAction() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.stayInChanged)
            .sink { [weak self] in await self?.stayInChangedAction($0) }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in await self?.didBecomeActiveAction() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in await self?.willResignActiveAction() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantReachabilityMonitor.reachabilityChanged)
            .sink { [weak self] in await self?.reachabilityChangedAction($0) }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantTransfersProvider.initialSyncFinished)
            .sink { [weak self] _ in await self?.getChatRooms(offset: nil) }
            .store(in: &subscriptions)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notifications action
    
    private func userLoggedInAction(_ notification: Notification) {
        let store = self.securedStore
        
        guard let loggedAddress = notification.userInfo?[AdamantUserInfoKey.AccountService.loggedAccountAddress] as? String else {
            store.remove(StoreKey.chatProvider.address)
            store.remove(StoreKey.chatProvider.receivedLastHeight)
            store.remove(StoreKey.chatProvider.readedLastHeight)
            self.dropStateData()
            return
        }
        
        if let savedAddress: String = store.get(StoreKey.chatProvider.address), savedAddress == loggedAddress {
            if let raw: String = store.get(StoreKey.chatProvider.readedLastHeight),
               let h = Int64(raw) {
                self.readedLastHeight = h
            }
        } else {
            store.remove(StoreKey.chatProvider.receivedLastHeight)
            store.remove(StoreKey.chatProvider.readedLastHeight)
            self.dropStateData()
            store.set(loggedAddress, for: StoreKey.chatProvider.address)
        }
        
        self.connectToSocket()
    }
    
    private func userLogOutAction() {
        // Drop everything
        reset()
        
        // BackgroundFetch
        dropStateData()
        
        blockList = []
        removedMessages = []
        
        disconnectFromSocket()
    }
    
    private func stayInChangedAction(_ notification: Notification) {
        guard let state = notification.userInfo?[AdamantUserInfoKey.AccountService.newStayInState] as? Bool,
              state
        else {
            return
        }
        
        if state {
            securedStore.set(blockList, for: StoreKey.accountService.blockList)
            securedStore.set(removedMessages, for: StoreKey.accountService.removedMessages)
        }
    }
    
    private func didBecomeActiveAction() async {
        if let previousAppState = previousAppState,
           previousAppState == .background {
            self.previousAppState = .active
            _ = await update(notifyState: true)
        }
    }
    
    private func willResignActiveAction() {
        if isInitiallySynced {
            previousAppState = .background
        }
    }
    
    private func reachabilityChangedAction(_ notification: Notification) {
        guard let connection = notification
            .userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool
        else {
            return
        }
        
        guard connection == true else {
            isConnectedToTheInternet = false
            return
        }
        
        if isConnectedToTheInternet == false {
            onConnectionToTheInternetRestored()
        }
        
        isConnectedToTheInternet = true
    }
    
    // MARK: Tools
    /// Free stateSemaphore before calling this method, or you will deadlock.
    private func setState(_ state: State, previous prevState: State, notify: Bool = true) {
        self.state = state
        
        guard notify else { return }
        
        if case .failedToUpdate = prevState {
            NotificationCenter.default.post(
                name: Notification.Name.AdamantTransfersProvider.stateChanged,
                object: self,
                userInfo: [
                    AdamantUserInfoKey.TransfersProvider.newState: state,
                    AdamantUserInfoKey.TransfersProvider.prevState: prevState
                ]
            )
            
            stateNotifier = state
            return
        }
        
        guard prevState != state else { return }
        
        NotificationCenter.default.post(
            name: Notification.Name.AdamantTransfersProvider.stateChanged,
            object: self,
            userInfo: [
                AdamantUserInfoKey.TransfersProvider.newState: state,
                AdamantUserInfoKey.TransfersProvider.prevState: prevState
            ]
        )
        
        stateNotifier = state
    }
    
    private func setupSecuredStore() {
        blockList = securedStore.get(StoreKey.accountService.blockList) ?? []
        removedMessages = securedStore.get(StoreKey.accountService.removedMessages) ?? []
    }
    
    func dropStateData() {
        securedStore.remove(StoreKey.chatProvider.notifiedLastHeight)
        securedStore.remove(StoreKey.chatProvider.notifiedMessagesCount)
    }
    
    func isMessageDeleted(id: String) -> Bool {
        removedMessages.contains(id)
    }
}

// MARK: - DataProvider
extension AdamantChatsProvider {
    func reload() async {
        reset(notify: false)
        _ = await update(notifyState: false)
    }
    
    func reset() {
        reset(notify: true)
    }
    
    private func reset(notify: Bool) {
        isInitiallySynced = false
        let prevState = self.state
        setState(.updating, previous: prevState, notify: false) // Block update calls
        
        // Drop props
        receivedLastHeight = nil
        readedLastHeight = nil
        roomsMaxCount = nil
        roomsLoadedCount = nil
        chatLoadingStatusDictionary.removeAll()
        chatMaxMessages.removeAll()
        chatLoadedMessages.removeAll()
        
        // Drop store
        securedStore.remove(StoreKey.chatProvider.address)
        securedStore.remove(StoreKey.chatProvider.receivedLastHeight)
        securedStore.remove(StoreKey.chatProvider.readedLastHeight)
        
        // Drop CoreData
//        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        context.parent = stack.container.viewContext
//
//        let trs = NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
//
//        if let results = try? context.fetch(trs) {
//            for obj in results {
//                context.delete(obj)
//            }
//
//            try! context.save()
//        }
        
        // Set State
        setState(.empty, previous: prevState, notify: notify)
    }
    
    func getChatRooms(offset: Int?) async {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey
        else {
            return
        }
        
        let prevState = state
        state = .updating
        
        // MARK: 3. Get transactions
        
        let chatrooms = try? await apiService.getChatRooms(
            address: address,
            offset: offset,
            waitsForConnectivity: true
        ).get()
        
        guard let chatrooms = chatrooms else {
            if !isInitiallySynced {
                isInitiallySynced = true
            }
            setState(.upToDate, previous: prevState)
            return
        }
        
        roomsMaxCount = chatrooms.count
        
        if let roomsLoadedCount = roomsLoadedCount {
            self.roomsLoadedCount = roomsLoadedCount + (chatrooms.chats?.count ?? 0)
        } else {
            self.roomsLoadedCount = chatrooms.chats?.count ?? 0
        }
        
        var array = [Transaction]()
        chatrooms.chats?.forEach({ room in
            if let last = room.lastTransaction {
                array.append(last)
            }
        })
        
        await process(
            messageTransactions: array,
            senderId: address,
            privateKey: privateKey
        )
        
        if !isInitiallySynced {
            isInitiallySynced = true
            preLoadChats(array, address: address)
        }
        
        setState(.upToDate, previous: prevState)
    }
    
    func preLoadChats(_ array: [Transaction], address: String) {
        let preLoadChatsCount = preLoadChatsCount
        array.prefix(preLoadChatsCount).forEach { transaction in
            let recipientAddress = transaction.recipientId == address ? transaction.senderId : transaction.recipientId
            Task {
                let isChatLoading = isChatLoading(with: recipientAddress)
                guard !isChatLoading else { return }
                await getChatMessages(with: recipientAddress, offset: nil)
            }
        }
    }
    
    func getChatMessages(with addressRecipient: String, offset: Int?) async {
        await getChatMessages(with: addressRecipient, offset: offset, loadedCount: .zero)
    }
    
    func getChatMessages(
        with addressRecipient: String,
        offset: Int?,
        loadedCount: Int
    ) async {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey else {
            return
        }
        
        // MARK: 3. Get transactions
        
        if getChatStatus(for: addressRecipient) == .none {
            setChatStatus(for: addressRecipient, status: .loading)
        }
        
        let chatroom = try? await apiGetChatMessages(
            address: address,
            addressRecipient: addressRecipient,
            offset: offset,
            limit: chatTransactionsLimit
        )
        
        guard let transactions = chatroom?.messages,
              transactions.count > 0
        else {
            setChatDoneStatus(
                for: addressRecipient,
                messageCount: 0,
                maxCount: chatroom?.count
            )
            return
        }
        
        let result = await process(
            messageTransactions: transactions,
            senderId: address,
            privateKey: privateKey
        )
        
        await processChatMessages(
            result: result,
            chatroom: chatroom,
            offset: offset,
            addressRecipient: addressRecipient,
            loadedCount: loadedCount
        )
    }
    
    func processChatMessages(
        result: (reactionsCount: Int, totalCount: Int),
        chatroom: ChatRooms?,
        offset: Int?,
        addressRecipient: String,
        loadedCount: Int
    ) async {
        let messageCount = chatroom?.messages?.count ?? 0
        
        let minRectionsCount = result.totalCount * minReactionsProcent / 100
        let newLoadedCount = loadedCount + (result.totalCount - result.reactionsCount)
        
        guard result.reactionsCount > minRectionsCount,
              newLoadedCount < chatTransactionsLimit
        else {
            setChatDoneStatus(
                for: addressRecipient,
                messageCount: messageCount,
                maxCount: chatroom?.count
            )
            
            NotificationCenter.default.post(
                name: .AdamantChatsProvider.initiallyLoadedMessages,
                object: addressRecipient
            )
            return
        }
        
        let offset = (offset ?? 0) + messageCount

        let loadedCount = chatLoadedMessages[addressRecipient] ?? 0
        chatLoadedMessages[addressRecipient] = loadedCount + messageCount
        
        return await getChatMessages(
            with: addressRecipient,
            offset: offset,
            loadedCount: newLoadedCount
        )
    }
    
    func setChatDoneStatus(
        for addressRecipient: String,
        messageCount: Int,
        maxCount: Int?
    ) {
        setChatStatus(for: addressRecipient, status: .loaded)
        chatMaxMessages[addressRecipient] = maxCount
        
        let loadedCount = chatLoadedMessages[addressRecipient] ?? 0
        chatLoadedMessages[addressRecipient] = loadedCount + messageCount
    }
    
    func apiGetChatMessages(
        address: String,
        addressRecipient: String,
        offset: Int?,
        limit: Int?
    ) async throws -> ChatRooms? {
        do {
            let chatrooms = try await apiService.getChatMessages(
                address: address,
                addressRecipient: addressRecipient,
                offset: offset,
                limit: limit
            ).get()
            return chatrooms
        } catch let error {
            guard case .networkError = error else {
                return nil
            }
            
            try await Task.sleep(interval: requestRepeatDelay)
            
            return try await apiGetChatMessages(
                address: address,
                addressRecipient: addressRecipient,
                offset: offset,
                limit: limit
            )
        }
    }
    
    func connectToSocket() {
        // MARK: 2. Prepare
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey else {
            return
        }

        // MARK: 3. Get transactions
        
        socketService.connect(address: address) { [weak self] result in
            switch result {
            case .success(let trans):
                Task { [weak self] in
                    await self?.process(
                        messageTransactions: [trans],
                        senderId: address,
                        privateKey: privateKey
                    )
                }
            case .failure:
                break
            }
        }
    }
    
    func disconnectFromSocket() {
        self.socketService.disconnect()
    }
    
    func update(notifyState: Bool) async -> ChatsProviderResult? {
        // MARK: 1. Check state
        guard isInitiallySynced,
              state != .updating
        else {
            return nil
        }
        
        // MARK: 2. Prepare
        let prevState = state
        
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey
        else {
            setState(.failedToUpdate(ChatsProviderError.notLogged), previous: prevState)
            return .failure(ChatsProviderError.notLogged)
        }
        
        setState(.updating, previous: prevState, notify: notifyState)
        
        // MARK: 3. Get transactions
        
        let prevHeight = receivedLastHeight
        
        try? await getTransactions(
            senderId: address,
            privateKey: privateKey,
            height: receivedLastHeight,
            offset: nil
        )
        
        // MARK: 4. Check
        
        switch state {
        case .upToDate, .empty, .updating:
            setState(.upToDate, previous: state, notify: notifyState)
            
            if prevHeight != receivedLastHeight,
               let h = receivedLastHeight {
                NotificationCenter.default.post(
                    name: Notification.Name.AdamantChatsProvider.newUnreadMessages,
                    object: self,
                    userInfo: [AdamantUserInfoKey.ChatProvider.lastMessageHeight:h]
                )
            }
            
            if let h = receivedLastHeight {
                readedLastHeight = h
            } else {
                readedLastHeight = 0
            }
            
            if let h = receivedLastHeight {
                securedStore.set(String(h), for: StoreKey.chatProvider.receivedLastHeight)
            }
            
            if let h = readedLastHeight,
               h > 0 {
                securedStore.set(String(h), for: StoreKey.chatProvider.readedLastHeight)
            }
            
            if !isInitiallySynced {
                isInitiallySynced = true
            }
            
            return .success
        case .failedToUpdate(let error): // Processing failed
            let err: ChatsProviderError
            
            switch error {
            case let error as ApiServiceError:
                switch error {
                case .notLogged:
                    err = .notLogged
                    
                case .accountNotFound:
                    err = .accountNotFound(address)
                    
                case .serverError, .commonError, .noEndpointsAvailable:
                    err = .serverError(error)
                    
                case .internalError(let message, _):
                    err = .dependencyError(message)
                    
                case .networkError:
                    err = .networkError
                    
                case .requestCancelled:
                    err = .requestCancelled
                }
                
            default:
                err = .internalError(error)
            }
            
            setState(.failedToUpdate(error), previous: state, notify: notifyState)
            return .failure(err)
        }
    }
    
    func isChatLoading(with addressRecipient: String) -> Bool {
        chatLoadingStatusDictionary[addressRecipient] == .loading
    }
    
    func isChatLoaded(with addressRecipient: String) -> Bool {
        chatLoadingStatusDictionary[addressRecipient] == .loaded
    }
    
    func getChatStatus(for recipient: String) -> ChatRoomLoadingStatus {
        chatLoadingStatusDictionary[recipient] ?? .none
    }
    
    func setChatStatus(for recipient: String, status: ChatRoomLoadingStatus) {
        chatLoadingStatusDictionary[recipient] = status
    }
}

// MARK: - Sending messages {
extension AdamantChatsProvider {
    func sendMessage(_ message: AdamantMessage, recipientId: String) async throws -> ChatTransaction {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            throw ChatsProviderError.notLogged
        }
        
        guard loggedAccount.balance >= message.fee else {
            throw ChatsProviderError.notEnoughMoneyToSend
        }
        
        switch validateMessage(message) {
        case .isValid:
            break
            
        case .empty:
            throw ChatsProviderError.messageNotValid(.empty)
        case .tooLong:
            throw ChatsProviderError.messageNotValid(.tooLong)
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        let transactionLocaly: ChatTransaction
        
        switch message {
        case .text(let text):
            transactionLocaly = try await sendTextMessageLocaly(
                text: text,
                isMarkdown: false,
                senderId: loggedAccount.address,
                recipientId: recipientId,
                keypair: keypair,
                type: message.chatType,
                context: context
            )
        case .markdownText(let text):
            transactionLocaly = try await sendTextMessageLocaly(
                text: text,
                isMarkdown: true,
                senderId: loggedAccount.address,
                recipientId: recipientId,
                keypair: keypair,
                type: message.chatType,
                context: context
            )
        case .richMessage(let payload):
            transactionLocaly = try await sendRichMessageLocaly(
                richContent: payload.content(),
                richContentSerialized: payload.serialized(),
                richType: payload.type,
                additionalType: payload.additionalType,
                senderId: loggedAccount.address,
                recipientId: recipientId,
                keypair: keypair,
                context: context
            )
        }
        
        let transaction = try await sendMessageToServer(
            senderId: loggedAccount.address,
            recipientId: recipientId,
            transaction: transactionLocaly,
            type: message.chatType,
            keypair: keypair,
            context: context
        )
        
        return transaction
    }
    
    @MainActor func removeChatPositon(for address: String) {
        chatPositon.removeValue(forKey: address)
    }
    
    @MainActor func setChatPositon(for address: String, position: Double?) {
        chatPositon[address] = position
    }
    
    @MainActor func getChatPositon(for address: String) -> Double? {
        return chatPositon[address]
    }
    
    /// Logic:
    /// create and write transaction in local database
    /// send transaction to server
    func sendMessage(_ message: AdamantMessage, recipientId: String, from chatroom: Chatroom?) async throws -> ChatTransaction {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            throw ChatsProviderError.notLogged
        }
        
        guard loggedAccount.balance >= message.fee else {
            throw ChatsProviderError.notEnoughMoneyToSend
        }
        
        switch validateMessage(message) {
        case .isValid:
            break
        case .empty:
            throw ChatsProviderError.messageNotValid(.empty)
        case .tooLong:
            throw ChatsProviderError.messageNotValid(.tooLong)
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        let transactionLocaly: ChatTransaction
        
        switch message {
        case .text(let text):
            transactionLocaly = try await sendTextMessageLocaly(
                text: text,
                isMarkdown: false,
                senderId: loggedAccount.address,
                recipientId: recipientId,
                keypair: keypair,
                type: message.chatType,
                context: context,
                from: chatroom
            )
        case .markdownText(let text):
            transactionLocaly = try await sendTextMessageLocaly(
                text: text,
                isMarkdown: true,
                senderId: loggedAccount.address,
                recipientId: recipientId,
                keypair: keypair,
                type: message.chatType,
                context: context,
                from: chatroom
            )
        case .richMessage(let payload):
            transactionLocaly = try await sendRichMessageLocaly(
                richContent: payload.content(),
                richContentSerialized: payload.serialized(),
                richType: payload.type,
                additionalType: payload.additionalType,
                senderId: loggedAccount.address,
                recipientId: recipientId,
                keypair: keypair,
                context: context,
                from: chatroom
            )
        }
        
        let transaction = try await sendMessageToServer(
            senderId: loggedAccount.address,
            recipientId: recipientId,
            transaction: transactionLocaly,
            type: message.chatType,
            keypair: keypair,
            context: context,
            from: chatroom
        )
        
        return transactionLocaly
    }
    
    func sendFileMessageLocally(
        _ message: AdamantMessage,
        recipientId: String,
        from chatroom: Chatroom?
    ) async throws -> String {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            throw ChatsProviderError.notLogged
        }
        
        guard loggedAccount.balance >= message.fee else {
            throw ChatsProviderError.notEnoughMoneyToSend
        }
        
        switch validateMessage(message) {
        case .isValid:
            break
        case .empty:
            throw ChatsProviderError.messageNotValid(.empty)
        case .tooLong:
            throw ChatsProviderError.messageNotValid(.tooLong)
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
                
        guard case let .richMessage(payload) = message else {
            throw ChatsProviderError.messageNotValid(.empty)
        }
        
        let transactionLocaly = try await sendRichMessageLocaly(
            richContent: payload.content(),
            richContentSerialized: payload.serialized(),
            richType: payload.type,
            additionalType: payload.additionalType,
            senderId: loggedAccount.address,
            recipientId: recipientId,
            keypair: keypair,
            context: context,
            from: chatroom
        )

        return transactionLocaly.transactionId
    }
    
    func sendFileMessage(
        _ message: AdamantMessage,
        recipientId: String,
        transactionLocalyId: String,
        from chatroom: Chatroom?
    ) async throws -> ChatTransaction {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            throw ChatsProviderError.notLogged
        }
        
        guard loggedAccount.balance >= message.fee else {
            throw ChatsProviderError.notEnoughMoneyToSend
        }
        
        switch validateMessage(message) {
        case .isValid:
            break
        case .empty:
            throw ChatsProviderError.messageNotValid(.empty)
        case .tooLong:
            throw ChatsProviderError.messageNotValid(.tooLong)
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        guard let transactionLocaly = getBaseTransactionFromDB(
            id: transactionLocalyId,
            context: context
        ) as? RichMessageTransaction
        else {
            throw ChatsProviderError.transactionNotFound(id: transactionLocalyId)
        }
        
        guard case let .richMessage(payload) = message else {
            throw ChatsProviderError.messageNotValid(.empty)
        }
        
        transactionLocaly.richContent = payload.content()
        transactionLocaly.richContentSerialized = payload.serialized()
        
        let transaction = try await sendMessageToServer(
            senderId: loggedAccount.address,
            recipientId: recipientId,
            transaction: transactionLocaly,
            type: message.chatType,
            keypair: keypair,
            context: context,
            from: chatroom
        )
        
        return transaction
    }
    
    func setTxMessageStatus(
        txId: String,
        status: MessageStatus
    ) throws {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        guard let transaction = getBaseTransactionFromDB(
            id: txId,
            context: context
        ) as? RichMessageTransaction
        else {
            throw ChatsProviderError.transactionNotFound(id: txId)
        }
        
        transaction.statusEnum = status
        try context.save()
    }
    
    func updateTxMessageContent(txId: String, richMessage: RichMessage) throws {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        guard let transaction = getBaseTransactionFromDB(
            id: txId,
            context: context
        ) as? RichMessageTransaction
        else {
            throw ChatsProviderError.transactionNotFound(id: txId)
        }
        
        transaction.richContent = richMessage.content()
        transaction.richContentSerialized = richMessage.serialized()
        try context.save()
    }
    
    private func sendTextMessageLocaly(
        text: String,
        isMarkdown: Bool,
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        type: ChatType,
        context: NSManagedObjectContext,
        from chatroom: Chatroom? = nil
    ) async throws -> ChatTransaction {
        let transaction = MessageTransaction(context: context)
        let id = UUID().uuidString
        transaction.date = Date() as NSDate
        transaction.recipientId = recipientId
        transaction.senderId = senderId
        transaction.type = Int16(type.rawValue)
        transaction.isOutgoing = true
        transaction.chatMessageId = id
        transaction.isMarkdown = isMarkdown
        transaction.transactionId = id
        
        transaction.message = text
        
        if
            let c = chatroom,
            let chatroom = context.object(with: c.objectID) as? Chatroom,
            let partner = chatroom.partner
        {
            transaction.statusEnum = MessageStatus.pending
            transaction.partner = context.object(with: partner.objectID) as? BaseAccount
            
            chatroom.addToTransactions(transaction)
            
            do {
                try context.save()
                return transaction
            } catch {
                throw ChatsProviderError.internalError(error)
            }
        }
        
        return transaction
    }
    
    private func sendRichMessageLocaly(
        richContent: [String: Any],
        richContentSerialized: String,
        richType: String,
        additionalType: RichAdditionalType,
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        context: NSManagedObjectContext,
        from chatroom: Chatroom? = nil
    ) async throws -> RichMessageTransaction {
        let type = ChatType.richMessage
        let id = UUID().uuidString
        let transaction = RichMessageTransaction(context: context)
        transaction.date = Date() as NSDate
        transaction.recipientId = recipientId
        transaction.senderId = senderId
        transaction.type = Int16(type.rawValue)
        transaction.isOutgoing = true
        transaction.chatMessageId = id
        transaction.transactionId = id
        transaction.richContent = richContent
        transaction.richType = richType
        transaction.additionalType = additionalType
        transaction.richContentSerialized = richContentSerialized
        transaction.blockchainType = richType
        transaction.richTransferHash = id
        
        transaction.transactionStatus = walletServiceCompose.getWallet(by: richType) != nil
        ? .notInitiated
        : nil
        
        if
            let c = chatroom,
            let chatroom = context.object(with: c.objectID) as? Chatroom,
            let partner = chatroom.partner
        {
            transaction.statusEnum = MessageStatus.pending
            transaction.partner = context.object(with: partner.objectID) as? BaseAccount
            
            chatroom.addToTransactions(transaction)
            
            do {
                try context.save()
                return transaction
            } catch {
                throw ChatsProviderError.internalError(error)
            }
        }
        
        return transaction
    }
    
    private func sendMessageToServer(
        senderId: String,
        recipientId: String,
        transaction: ChatTransaction,
        type: ChatType,
        keypair: Keypair,
        context: NSManagedObjectContext,
        from chatroom: Chatroom? = nil
    ) async throws -> ChatTransaction {
        let sendTransaction = try await prepareAndSendChatTransaction(
            transaction,
            in: context,
            recipientId: recipientId,
            type: type,
            keypair: keypair,
            from: chatroom
        )
        
        return sendTransaction
    }
    
    /// Transaction must be in passed context
    private func prepareAndSendChatTransaction(
        _ transaction: ChatTransaction,
        in context: NSManagedObjectContext,
        recipientId: String,
        type: ChatType,
        keypair: Keypair,
        from chatroom: Chatroom? = nil
    ) async throws -> ChatTransaction {
        
        // MARK: 1. Get account
        
        do {
            let recipientAccount = try await accountsProvider.getAccount(byAddress: recipientId)
            
            guard let recipientPublicKey = recipientAccount.publicKey else {
                throw ChatsProviderError.accountNotFound(recipientId)
            }
            
            let isAdded = chatroom == nil
            
            // MARK: 2. Get Chatroom
            
            guard let id = recipientAccount.chatroom?.objectID,
                  let chatroom = context.object(with: id) as? Chatroom
            else {
                throw ChatsProviderError.accountNotFound(recipientId)
            }
            
            // MARK: 3. Prepare transaction
            
            transaction.statusEnum = MessageStatus.pending
            transaction.partner = context.object(with: recipientAccount.objectID) as? BaseAccount
            
            if isAdded {
                chatroom.addToTransactions(transaction)
            }
            
            // MARK: 4. Last in
            
            if let lastTransaction = chatroom.lastTransaction {
                if let dateA = lastTransaction.date as Date?,
                   let dateB = transaction.date as Date?,
                    dateA.compare(dateB) == ComparisonResult.orderedAscending {
                    chatroom.lastTransaction = transaction
                    chatroom.updatedAt = transaction.date
                }
            } else {
                chatroom.lastTransaction = transaction
                chatroom.updatedAt = transaction.date
            }
            
            defer {
                try? context.save()
            }
            
            return try await sendTransaction(
                transaction,
                type: type,
                keypair: keypair,
                recipientPublicKey: recipientPublicKey
            )
        } catch let error as AccountsProviderError {
            switch error {
            case .notFound, .invalidAddress:
                throw ChatsProviderError.accountNotFound(recipientId)
            case .notInitiated, .dummy:
                throw ChatsProviderError.accountNotInitiated(recipientId)
            case .serverError(let error):
                throw ChatsProviderError.serverError(error)
            case .networkError:
                throw ChatsProviderError.networkError
            }
        } catch {
            throw error
        }
    }
    
    func retrySendMessage(_ message: ChatTransaction) async throws {
        // MARK: 0. Prepare
        switch message.statusEnum {
        case .delivered, .pending:
           return
        case .failed:
            break
        }
        
        guard let keypair = accountService.keypair else {
            throw ChatsProviderError.notLogged
        }
        
        guard let recipientPublicKey = message.chatroom?.partner?.publicKey else {
            throw ChatsProviderError.accountNotFound(message.recipientId ?? "")
        }
        
        // MARK: 1. Prepare private context
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        guard let transaction = privateContext.object(with: message.objectID) as? MessageTransaction else {
            throw ChatsProviderError.notLogged
        }
        
        // MARK: 2. Update transaction
        transaction.date = Date() as NSDate
        transaction.statusEnum = .pending
        
        if let chatroom = transaction.chatroom {
            if let lastTransaction = chatroom.lastTransaction {
                if let dateA = lastTransaction.date as Date?, let dateB = transaction.date as Date?,
                    dateA.compare(dateB) == ComparisonResult.orderedAscending {
                    chatroom.lastTransaction = transaction
                    chatroom.updatedAt = transaction.date
                }
            } else {
                chatroom.lastTransaction = transaction
                chatroom.updatedAt = transaction.date
            }
        }
        
        defer {
            try? privateContext.save()
        }
        
        _ = try await sendTransaction(
            transaction,
            type: .message,
            keypair: keypair,
            recipientPublicKey: recipientPublicKey
        )
    }
    
    // MARK: - Delete local message
    func cancelMessage(_ message: ChatTransaction)  async throws {
        // MARK: 0. Prepare
        switch message.statusEnum {
        case .delivered, .pending:
            // We can't cancel sent transactions
            throw ChatsProviderError.invalidTransactionStatus
        case .failed:
            break
        }
        
        // MARK: 1. Find. Destroy. Save.
        
        let chatroom = message.chatroom
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        privateContext.delete(privateContext.object(with: message.objectID))
        do {
            try privateContext.save()
            if let chatroom = chatroom {
                await updateLastTransactionForChatrooms([chatroom])
            }
        } catch {
            throw ChatsProviderError.internalError(error)
        }
    }
    
    // MARK: - Logic
    
    /// Send transaction.
    ///
    /// If success - update transaction's id, status and add it to unconfirmed transactions.
    /// If fails - set transaction status to .failed
    private func sendTransaction(
        _ transaction: ChatTransaction,
        type: ChatType,
        keypair: Keypair,
        recipientPublicKey: String
    ) async throws -> ChatTransaction {
        // MARK: 0. Prepare
        guard let senderId = transaction.senderId,
            let recipientId = transaction.recipientId else {
            throw ChatsProviderError.accountNotFound(recipientPublicKey)
        }
        
        // MARK: 1. Encode
        guard let text = transaction.serializedMessage(),
              let encodedMessage = adamantCore.encodeMessage(
                text,
                recipientPublicKey: recipientPublicKey,
                privateKey: keypair.privateKey
              )
        else {
            throw ChatsProviderError.dependencyError("Failed to encode message")
        }
        
        // MARK: 2. Create
        let signedTransaction = try? adamantCore.makeSendMessageTransaction(
            senderId: senderId,
            recipientId: recipientId,
            keypair: keypair,
            message: encodedMessage.message,
            type: type,
            nonce: encodedMessage.nonce,
            amount: nil
        )
        
        guard let signedTransaction = signedTransaction else {
            throw ChatsProviderError.internalError(AdamantError(message: InternalAPIError.signTransactionFailed.localizedDescription))
        }
        
        unconfirmedTransactionsBySignature.append(signedTransaction.signature)
        
        // MARK: 3. Send
        
        do {
            let locallyID = signedTransaction.generateId() ?? UUID().uuidString
            transaction.transactionId = locallyID
            transaction.chatMessageId = locallyID
            
            let id = try await apiService.sendMessageTransaction(transaction: signedTransaction).get()
            
            // Update ID with recieved, add to unconfirmed transactions.
            transaction.transactionId = String(id)
            transaction.chatMessageId = String(id)
            transaction.statusEnum = .delivered
            
            removeTxFromUnconfirmed(
                signature: signedTransaction.signature,
                transaction: transaction
            )
                        
            return transaction
        } catch {
            guard case let(apiError) = (error as? ApiServiceError),
                  case let(.serverError(text)) = apiError,
                  text.contains("Transaction is already confirmed")
                    || text.contains("Transaction is already processed")
            else {
                transaction.statusEnum = .failed
                throw handleTransactionError(error, recipientId: recipientId)
            }
            
            transaction.statusEnum = .pending
            
            removeTxFromUnconfirmed(
                signature: signedTransaction.signature,
                transaction: transaction
            )
            
            return transaction
        }
    }
    
    func removeTxFromUnconfirmed(
        signature: String,
        transaction: ChatTransaction
    ) {
        if let index = unconfirmedTransactionsBySignature.firstIndex(
            of: signature
        ) {
            unconfirmedTransactionsBySignature.remove(at: index)
        }
        
        unconfirmedTransactions[UInt64(transaction.transactionId) ?? .zero] = transaction.objectID
    }
    
    func handleTransactionError(_ error: Error, recipientId: String) -> Error {
        switch error as? ApiServiceError {
        case .networkError:
            return ChatsProviderError.networkError
        case .accountNotFound:
            return ChatsProviderError.accountNotFound(recipientId)
        case .notLogged:
            return ChatsProviderError.notLogged
        case .serverError(let e), .commonError(let e):
            return ChatsProviderError.serverError(AdamantError(message: e))
        case .noEndpointsAvailable:
            return ChatsProviderError.serverError(AdamantError(
                message: error.localizedDescription
            ))
        case .internalError(let message, _):
            return ChatsProviderError.internalError(AdamantError(message: message))
        case .requestCancelled:
            return ChatsProviderError.requestCancelled
        case .none:
            return ChatsProviderError.serverError(error)
        }
    }
}

// MARK: - Getting messages
extension AdamantChatsProvider {
    func getChatroomsController() -> NSFetchedResultsController<Chatroom> {
        let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false),
                                   NSSortDescriptor(key: "title", ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "partner!=nil"),
            NSPredicate(format: "isForcedVisible = true OR isHidden = false"),
            NSPredicate(format: "isForcedVisible = true OR ANY transactions.showsChatroom = true")
        ])
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }
    
    func getChatroom(for adm: String) -> Chatroom? {
        let request: NSFetchRequest<Chatroom> = NSFetchRequest(entityName: Chatroom.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false),
                                   NSSortDescriptor(key: "title", ascending: true)]
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "partner!=nil"),
            NSPredicate(format: "partner.address CONTAINS[cd] %@", adm),
            NSPredicate(format: "isForcedVisible = true OR isHidden = false"),
            NSPredicate(format: "isForcedVisible = true OR ANY transactions.showsChatroom = true")
        ])
        
        do {
            let result = try stack.container.viewContext.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
    
    @MainActor func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction> {
        guard let context = chatroom.managedObjectContext else {
            fatalError()
        }
        
        let request: NSFetchRequest<ChatTransaction> = NSFetchRequest(entityName: "ChatTransaction")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "chatroom = %@", chatroom),
            NSPredicate(format: "isHidden == false")])
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true),
                                   NSSortDescriptor(key: "transactionId", ascending: true)]
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        return controller
    }
    
    func getUnreadMessagesController() -> NSFetchedResultsController<ChatTransaction> {
        let request = NSFetchRequest<ChatTransaction>(entityName: "ChatTransaction")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "chatroom.isHidden == false"),
            NSPredicate(format: "isUnread == true"),
            NSPredicate(format: "isHidden == false")])
        
        request.sortDescriptors = [NSSortDescriptor.init(key: "date", ascending: false),
                                   NSSortDescriptor(key: "transactionId", ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: "chatroom.partner.address", cacheName: nil)
        
        return controller
    }
    
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getTransfer(id: String, context: NSManagedObjectContext) -> TransferTransaction? {
        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        
        do {
            let result = try context.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
    
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getBaseTransactionFromDB(id: String, context: NSManagedObjectContext) -> BaseTransaction? {
        let request = NSFetchRequest<BaseTransaction>(entityName: "BaseTransaction")
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        
        do {
            let result = try context.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
}

// MARK: - Processing
extension AdamantChatsProvider {
    /// Get new transactions
    ///
    /// - Parameters:
    ///   - account: for account
    ///   - height: last message height. Minimum == 1 !!!
    ///   - offset: offset, if greater than 100
    /// - Returns: ammount of new messages was added
    private func getTransactions(
        senderId: String,
        privateKey: String,
        height: Int64?,
        offset: Int?
    ) async throws {
        if self.accountService.account == nil {
            throw ApiServiceError.accountNotFound
        }
        
        do {
            let transactions = try await apiService.getMessageTransactions(
                address: senderId,
                height: height,
                offset: offset
            ).get()
            
            if transactions.count == 0 {
                return
            }
            
            await process(
                messageTransactions: transactions,
                senderId: senderId,
                privateKey: privateKey
            )
            
            // MARK: Get more transactions if needed
            if transactions.count == self.apiTransactions {
                let newOffset: Int
                if let offset = offset {
                    newOffset = offset + self.apiTransactions
                } else {
                    newOffset = self.apiTransactions
                }
                
                try await getTransactions(
                    senderId: senderId,
                    privateKey: privateKey,
                    height: height,
                    offset: newOffset
                )
            }
        } catch {
            self.setState(.failedToUpdate(error), previous: .updating)
            throw error
        }
    }
    
    func loadTransactionsUntilFound(
        _ transactionId: String,
        recipient: String
    ) async throws {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey
        else {
            throw ApiServiceError.accountNotFound
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.stack.container.viewContext
        
        guard getBaseTransactionFromDB(id: transactionId, context: context) == nil else { return }
                
        var transactions: [Transaction] = []
        var offset = chatLoadedMessages[recipient] ?? 0
        var needToRepeat = false
        var isFound = false
        
        repeat {
            let messages = try await apiGetChatMessages(
                address: address,
                addressRecipient: recipient,
                offset: offset,
                limit: chatTransactionsLimit
            )?.messages
            
            guard let messages = messages else {
                needToRepeat = false
                break
            }
            
            offset += messages.count
            transactions.append(contentsOf: messages)
            isFound = transactions.contains(where: { $0.id == UInt64(transactionId) })
            needToRepeat = messages.count >= chatTransactionsLimit && !isFound
        } while needToRepeat
        
        guard isFound else {
            throw ApiServiceError.commonError(
                message: String.adamant.reply.longUnknownMessageError
            )
        }
        
        chatLoadedMessages[recipient] = offset
        
        await process(
            messageTransactions: transactions,
            senderId: address,
            privateKey: privateKey
        )
        
        // MARK: Get more transactions
        
        let messages = try await apiGetChatMessages(
            address: address,
            addressRecipient: recipient,
            offset: offset,
            limit: chatTransactionsLimit
        )?.messages
        
        guard let messages = messages, messages.count > 0 else { return }

        chatLoadedMessages[recipient] = offset + messages.count
        
        await process(
            messageTransactions: messages,
            senderId: address,
            privateKey: privateKey
        )
    }
    
    /// - New unread messagess ids
    @discardableResult private func process(
        messageTransactions: [Transaction],
        senderId: String,
        privateKey: String
    ) async -> (reactionsCount: Int, totalCount: Int) {
        struct DirectionedTransaction {
            let transaction: Transaction
            let isOut: Bool
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.stack.container.viewContext
        context.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
        
        // MARK: 1. Gather partner keys
        let mapped = messageTransactions.map({ DirectionedTransaction(transaction: $0, isOut: $0.senderId == senderId) })
        let grouppedTransactions = Dictionary(grouping: mapped, by: { $0.isOut ? $0.transaction.recipientId : $0.transaction.senderId })
        
        // MARK: 2. Gather Accounts
        var partners: [CoreDataAccount: [DirectionedTransaction]] = [:]
        
        let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
        request.fetchLimit = grouppedTransactions.count
        let predicates = grouppedTransactions.keys.map { NSPredicate(format: "address = %@", $0) }
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        do {
            let results = try context.fetch(request)
            for account in results {
                if let address = account.address, let transactions = grouppedTransactions[address] {
                    partners[account] = transactions
                }
            }
        } catch {
            print("NSPredicate fetch error \(error.localizedDescription)")
        }
        
        // MARK: 2.5 Get accounts, that we did not found.
        if partners.count != grouppedTransactions.keys.count {
            let foundedKeys = partners.keys.compactMap {$0.address}
            let notFound = Set<String>(grouppedTransactions.keys).subtracting(foundedKeys)
            var ids = [NSManagedObjectID]()
            
            for address in notFound {
                let transaction = grouppedTransactions[address]?.first
                let isOut = transaction?.isOut ?? false
                
                let publicKey = isOut
                ? transaction?.transaction.recipientPublicKey
                : transaction?.transaction.senderPublicKey
                
                do {
                    let account = try await accountsProvider.getAccount(
                        byAddress: address,
                        publicKey: publicKey ?? ""
                    )
                    
                    ids.append(account.objectID)
                } catch AccountsProviderError.dummy(let dummyAccount) {
                    ids.append(dummyAccount.objectID)
                } catch {
                    print(error)
                }
            }
            
            // Get in our context
            for id in ids {
                if let account = context.object(with: id) as? CoreDataAccount,
                   let address = account.address,
                   let transactions = grouppedTransactions[address] {
                    partners[account] = transactions
                }
            }
        }
        
        if partners.count != grouppedTransactions.keys.count {
            // TODO: Log this strange thing
            print("Failed to get all accounts: Needed keys:\n\(grouppedTransactions.keys.joined(separator: "\n"))\nFounded Addresses: \(partners.keys.compactMap { $0.address }.joined(separator: "\n"))")
        }
        
        // MARK: 3. Process Chatrooms and Transactions
        var height: Int64 = 0
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = context
        privateContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
        
        var newMessageTransactions = [ChatTransaction]()
        var transactionInProgress: [UInt64] = []
        
        var reactions = 0
        
        for (account, transactions) in partners {
            // We can't save whole context while we are mass creating MessageTransactions.
            guard let chatroom = account.chatroom else { continue }
            let privateChatroom = privateContext.object(with: chatroom.objectID) as! Chatroom
            
            // MARK: Transactions
            var messages = Set<ChatTransaction>()
            
            for trs in transactions {
                transactionInProgress.append(trs.transaction.id)
                if let objectId = unconfirmedTransactions[trs.transaction.id],
                   let unconfirmed = context.object(with: objectId) as? ChatTransaction {
                    confirmTransaction(
                        unconfirmed,
                        id: trs.transaction.id,
                        height: Int64(trs.transaction.height),
                        blockId: trs.transaction.blockId,
                        confirmations: trs.transaction.confirmations
                    )
                    
                    let h = Int64(trs.transaction.height)
                    if height < h {
                        height = h
                    }
                    continue
                }
                
                // if transaction in pending status then ignore it
                if unconfirmedTransactionsBySignature.contains(trs.transaction.signature) {
                    continue
                }
                
                let publicKey: String
                if trs.isOut {
                    publicKey = account.publicKey ?? ""
                } else {
                    publicKey = trs.transaction.senderPublicKey
                }
                
                if let partner = privateContext.object(with: account.objectID) as? BaseAccount,
                   let chatTransaction = await transactionService.chatTransaction(
                    from: trs.transaction,
                    isOutgoing: trs.isOut,
                    publicKey: publicKey,
                    privateKey: privateKey,
                    partner: partner,
                    removedMessages: self.removedMessages,
                    context: privateContext
                   ) {
                    if let transaction = chatTransaction as? RichMessageTransaction,
                       transaction.additionalType == .reaction {
                        reactions += 1
                    }
                    if height < chatTransaction.height {
                        height = chatTransaction.height
                    }
                    
                    let transactionExist = privateChatroom.transactions?.first(where: { message in
                        return (message as? ChatTransaction)?.txId == chatTransaction.txId
                    }) as? ChatTransaction
                    
                    if !trs.isOut {
                        if transactionExist == nil {
                            newMessageTransactions.append(chatTransaction)
                        }
                        
                        // Preset messages
                        if account.isSystem, let address = account.address,
                            let messages = AdamantContacts.messagesFor(address: address),
                            let messageTransaction = chatTransaction as? MessageTransaction,
                            let key = messageTransaction.message,
                            let systemMessage = messages.first(where: { key.range(of: $0.key) != nil })?.value {
                            
                            switch systemMessage.message {
                            case .text(let text):
                                messageTransaction.message = text
                                
                            case .markdownText(let text):
                                messageTransaction.message = text
                                messageTransaction.isMarkdown = true
                                
                            case .richMessage(let payload):
                                messageTransaction.message = payload.serialized()
                            }
                            
                            messageTransaction.silentNotification = systemMessage.silentNotification
                        }
                    }
                    
                    if transactionExist == nil {
                        if (chatTransaction.blockId?.isEmpty ?? true) && (chatTransaction.amountValue ?? 0.0 > 0.0) {
                            chatTransaction.statusEnum = .pending
                        }
                        messages.insert(chatTransaction)
                    } else {
                        transactionExist?.height = chatTransaction.height
                        transactionExist?.blockId = chatTransaction.blockId
                        transactionExist?.confirmations = chatTransaction.confirmations
                        transactionExist?.statusEnum = .delivered
                    }
                }
            }
            
            if !messages.isEmpty {
                privateChatroom.addToTransactions(messages as NSSet)
            }
            
            if let address = privateChatroom.partner?.address {
                chatroom.isHidden = self.blockList.contains(address)
            }
        }
        
        // MARK: 4. Unread messagess
        if let readedLastHeight = readedLastHeight {
            var unreadTransactions = newMessageTransactions.filter { $0.height > readedLastHeight }
            if unreadTransactions.count == 0 {
                unreadTransactions = newMessageTransactions.filter { $0.height == 0 }
            }
            let chatrooms = Dictionary(grouping: unreadTransactions, by: ({ (t: ChatTransaction) -> Chatroom in t.chatroom! }))
            for (chatroom, trs) in chatrooms {
                if let address = chatroom.partner?.address {
                    chatroom.isHidden = self.blockList.contains(address)
                }
                chatroom.hasUnreadMessages = true
                trs.forEach { $0.isUnread = true }
            }
        }
        
        // MARK: 5. Dump new transactions
        if privateContext.hasChanges {
            do {
                try privateContext.save()
            } catch {
                print(error)
            }
        }
        
        // MARK: 6. Save to main!
        do {
            let rooms = partners.keys.compactMap { $0.chatroom }
            
            if context.hasChanges {
                try context.save()
                await updateLastTransactionForChatrooms(rooms)
            }
        } catch {
            print(error)
        }
        
        // MARK: 7. Last message height
        if let lastHeight = receivedLastHeight {
            if lastHeight < height {
                updateLastHeight(height: height)
            }
        } else {
            updateLastHeight(height: height)
        }
        
        return (reactionsCount: reactions, totalCount: messageTransactions.count)
    }
    
    func updateLastHeight(height: Int64) {
        receivedLastHeight = height
    }
    
    @MainActor 
    func updateLastTransactionForChatrooms(_ rooms: [Chatroom]) {
        let viewContextChatrooms = Set<Chatroom>(rooms).compactMap {
            self.stack.container.viewContext.object(with: $0.objectID) as? Chatroom
        }
        
        for chatroom in viewContextChatrooms {
            chatroom.updateLastTransaction()
        }
    }
}

// MARK: - Tools
extension AdamantChatsProvider {
    
    func addUnconfirmed(transactionId id: UInt64, managedObjectId: NSManagedObjectID) {
        self.unconfirmedTransactions[id] = managedObjectId
    }
    
    /// Check if message is valid for sending
    func validateMessage(_ message: AdamantMessage) -> ValidateMessageResult {
        switch message {
        case .text(let text), .markdownText(let text):
            if text.count == 0 {
                return .empty
            }
            
            if Double(text.count) * 1.5 > 20000.0 {
                return .tooLong
            }
            
            return .isValid
            
        case .richMessage(let payload):
            let text = payload.serialized()
            
            if text.count == 0 {
                return .empty
            }
            
            if Double(text.count) * 1.5 > 20000.0 {
                return .tooLong
            }
            
            return .isValid
        }
    }
    
    /// Confirm transactions
    ///
    /// - Parameters:
    ///   - transaction: Unconfirmed transaction
    ///   - id: New transaction id    ///   - height: New transaction height
    private func confirmTransaction(_ transaction: ChatTransaction, id: UInt64, height: Int64, blockId: String, confirmations: Int64) {
        if transaction.isConfirmed {
            return
        }
        
        transaction.height = height
        transaction.blockId = blockId
        transaction.confirmations = confirmations
        
        if !blockId.isEmpty {
            self.unconfirmedTransactions.removeValue(forKey: id)
        }
        
        if let lastHeight = receivedLastHeight, lastHeight < height {
            self.receivedLastHeight = height
        }
        
        if height != .zero {
            transaction.isConfirmed = true
        }
        transaction.statusEnum = .delivered
    }
    
    func blockChat(with address: String) {
        if !self.blockList.contains(address) {
            self.blockList.append(address)
            
            if self.accountService.hasStayInAccount {
                self.securedStore.set(blockList, for: StoreKey.accountService.blockList)
            }
        }
    }
    
    func removeMessage(with id: String) {
        if !self.removedMessages.contains(id) {
            self.removedMessages.append(id)
            
            if self.accountService.hasStayInAccount {
                self.securedStore.set(removedMessages, for: StoreKey.accountService.removedMessages)
            }
        }
    }
    
    func markChatAsRead(chatroom: Chatroom) {
        chatroom.managedObjectContext?.perform {
            chatroom.markAsReaded()
            try? chatroom.managedObjectContext?.save()
        }
    }
    
    private func onConnectionToTheInternetRestored() {
        onConnectionToTheInternetRestoredTasks.forEach { $0() }
        onConnectionToTheInternetRestoredTasks = []
    }
}

private let requestRepeatDelay: TimeInterval = 2
