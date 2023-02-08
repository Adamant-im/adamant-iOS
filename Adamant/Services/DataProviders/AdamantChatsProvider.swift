//
//  AdamantChatsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData
import MarkdownKit

actor AdamantChatsProvider: ChatsProvider {
    
    // MARK: Dependencies
    let accountService: AccountService
    let apiService: ApiService
    let socketService: SocketService
    let stack: CoreDataStack
    let adamantCore: AdamantCore
    let accountsProvider: AccountsProvider
    let transactionService: ChatTransactionService
    let securedStore: SecuredStore
    let richTransactionStatusService: RichTransactionStatusService
    
    private let richProviders: [String: RichMessageProviderWithStatusCheck]
    
    // MARK: Properties
    private(set) var state: State = .empty
    private(set) var receivedLastHeight: Int64?
    private(set) var readedLastHeight: Int64?
    private let apiTransactions = 100
    private var unconfirmedTransactions: [UInt64:NSManagedObjectID] = [:]
    private var unconfirmedTransactionsBySignature: [String] = []
    
    var chatPositon: [String : Double] = [:]
    private(set) var blockList: [String] = []
    private(set) var removedMessages: [String] = []
    
    var isChatLoaded: [String : Bool] = [:]
    var chatMaxMessages: [String : Int] = [:]
    var chatLoadedMessages: [String : Int] = [:]
    private var chatsLoading: [String] = []
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
    
    // MARK: Lifecycle
    init(
        accountService: AccountService,
        apiService: ApiService,
        socketService: SocketService,
        stack: CoreDataStack,
        adamantCore: AdamantCore,
        accountsProvider: AccountsProvider,
        transactionService: ChatTransactionService,
        securedStore: SecuredStore,
        richTransactionStatusService: RichTransactionStatusService
    ) {
        self.accountService = accountService
        self.apiService = apiService
        self.socketService = socketService
        self.stack = stack
        self.adamantCore = adamantCore
        self.accountsProvider = accountsProvider
        self.transactionService = transactionService
        self.securedStore = securedStore
        self.richTransactionStatusService = richTransactionStatusService
        
        var richProviders = [String: RichMessageProviderWithStatusCheck]()
        for case let provider as RichMessageProviderWithStatusCheck in accountService.wallets {
            richProviders[provider.dynamicRichMessageType] = provider
        }
        self.richProviders = richProviders
        
        Task {
            await setupSecuredStore()
            
            await addObservers()
        }
    }
    
    func addObservers() async {
        for await notification in NotificationCenter.default.notifications(
            named: .AdamantAccountService.userLoggedIn
        ) {
            userLoggedInAction(notification)
        }
        
        for await _ in NotificationCenter.default.notifications(
            named: .AdamantAccountService.userLoggedOut
        ) {
            userLogOutAction()
        }
        
        for await notification in NotificationCenter.default.notifications(
            named: .AdamantAccountService.stayInChanged
        ) {
            stayInChangedAction(notification)
        }
        
        for await _ in await NotificationCenter.default.notifications(
            named: UIApplication.didBecomeActiveNotification
        ) {
            didBecomeActiveAction()
        }
        
        for await _ in await NotificationCenter.default.notifications(
            named: UIApplication.willResignActiveNotification
        ) {
            willResignActiveAction()
        }
        
        for await notification in NotificationCenter.default.notifications(
            named: .AdamantReachabilityMonitor.reachabilityChanged
        ) {
            reachabilityChangedAction(notification)
        }
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
        
        Task { [weak self] in
            await self?.getChatRooms(offset: nil)
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
    
    private func didBecomeActiveAction() {
        if let previousAppState = previousAppState,
           previousAppState == .background {
            self.previousAppState = .active
            update()
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
        
        if notify {
            switch prevState {
            case .failedToUpdate:
                NotificationCenter.default.post(name: Notification.Name.AdamantTransfersProvider.stateChanged, object: self, userInfo: [AdamantUserInfoKey.TransfersProvider.newState: state,
                                                                                                                    AdamantUserInfoKey.TransfersProvider.prevState: prevState])
                
            default:
                if prevState != self.state {
                    NotificationCenter.default.post(name: Notification.Name.AdamantTransfersProvider.stateChanged, object: self, userInfo: [AdamantUserInfoKey.TransfersProvider.newState: state,
                                                                                                                        AdamantUserInfoKey.TransfersProvider.prevState: prevState])
                }
            }
        }
    }
    
    private func setupSecuredStore() {
        blockList = securedStore.get(StoreKey.accountService.blockList) ?? []
        removedMessages = securedStore.get(StoreKey.accountService.removedMessages) ?? []
    }
    
    func dropStateData() {
        securedStore.remove(StoreKey.chatProvider.notifiedLastHeight)
        securedStore.remove(StoreKey.chatProvider.notifiedMessagesCount)
    }
}

// MARK: - DataProvider
extension AdamantChatsProvider {
    func reload() {
        reset(notify: false)
        update()
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
        isChatLoaded.removeAll()
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
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        
        let chatrooms = try? await apiGetChatrooms(address: address, offset: offset)
        
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
            privateKey: privateKey,
            context: privateContext
        )
        
        if !isInitiallySynced {
            isInitiallySynced = true
        }
        
        setState(.upToDate, previous: prevState)
        preLoadChats(array, address: address)
    }
    
    func preLoadChats(_ array: [Transaction], address: String) {
        let preLoadChatsCount = preLoadChatsCount
        array.prefix(preLoadChatsCount).forEach { transaction in
            let recipientAddress = transaction.recipientId == address ? transaction.senderId : transaction.recipientId
            Task {
                await getChatMessages(with: recipientAddress, offset: nil)
            }
        }
    }
    
    func waitUntilInternetConnectionRestore() {
        while !isConnectedToTheInternet {
            sleep(1)
        }
        return
    }
    
    func apiGetChatrooms(address: String, offset: Int?) async throws -> ChatRooms? {
        do {
            let chatrooms = try await apiService.getChatRooms(address: address, offset: offset)
            return chatrooms
        } catch {
            guard let error = error as? ApiServiceError,
                  case .networkError = error
            else {
                return nil
            }
            
            try? await Task.sleep(nanoseconds: requestRepeatDelayNanoseconds)
            return try await apiGetChatrooms(address: address, offset: offset)
        }
    }
    
    func getChatMessages(with addressRecipient: String, offset: Int?) async {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey else {
            return
        }
        
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
      
        if !isChatLoaded.keys.contains(addressRecipient) {
            chatsLoading.append(addressRecipient)
        }
        
        let chatroom = try? await apiGetChatMessages(
            address: address,
            addressRecipient: addressRecipient,
            offset: offset
        )
        
        isChatLoaded[addressRecipient] = true
        chatMaxMessages[addressRecipient] = chatroom?.count ?? 0
        
        let loadedCount = chatLoadedMessages[addressRecipient] ?? 0
        chatLoadedMessages[addressRecipient] = loadedCount + (chatroom?.messages?.count ?? 0)
        
        if let index = chatsLoading.firstIndex(of: addressRecipient) {
            chatsLoading.remove(at: index)
        }
        
        guard let transactions = chatroom?.messages,
              transactions.count > 0
        else {
            return
        }
        
        await process(
            messageTransactions: transactions,
            senderId: address,
            privateKey: privateKey,
            context: privateContext
        )
        
        NotificationCenter.default.post(name: .AdamantChatsProvider.initiallyLoadedMessages, object: addressRecipient)
    }
    
    func apiGetChatMessages(
        address: String,
        addressRecipient: String,
        offset: Int?
    ) async throws -> ChatRooms? {
        do {
            let chatrooms = try await apiService.getChatMessages(
                address: address,
                addressRecipient: addressRecipient,
                offset: offset
            )
            return chatrooms
        } catch {
            guard let error = error as? ApiServiceError,
                  case .networkError = error
            else {
                return nil
            }
            
            try? await Task.sleep(nanoseconds: requestRepeatDelayNanoseconds)
            return try await apiGetChatrooms(address: address, offset: offset)
        }
    }
    
    func update() {
        self.update(completion: nil)
    }
    
    func connectToSocket() {
        // MARK: 2. Prepare
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey else {
            return
        }

        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        
        socketService.connect(address: address) { [weak self] result in
            switch result {
            case .success(let trans):
                Task { [weak self] in
                    await self?.process(messageTransactions: [trans],
                                  senderId: address,
                                  privateKey: privateKey,
                                  context: privateContext)
                    
                }
            case .failure:
                break
            }
        }
    }
    
    func disconnectFromSocket() {
        self.socketService.disconnect()
    }
    
    func update(completion: ((ChatsProviderResult?) -> Void)?) {
        Task {
            let result = await update()
            completion?(result)
        }
    }
    
    func update() async -> ChatsProviderResult? {
        if state == .updating {
            return nil
        }
        
        // MARK: 1. Check state
        if state == .updating {
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
        
        state = .updating
        
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        let prevHeight = receivedLastHeight
        
        try? await getTransactions(senderId: address, privateKey: privateKey, height: receivedLastHeight, offset: nil, context: privateContext)
        
        // MARK: 4. Check
        
        switch state {
        case .upToDate, .empty, .updating:
            setState(.upToDate, previous: prevState)
            
            if prevHeight != receivedLastHeight,
               let h = receivedLastHeight {
                NotificationCenter.default.post(name: Notification.Name.AdamantChatsProvider.newUnreadMessages,
                                                object: self,
                                                userInfo: [AdamantUserInfoKey.ChatProvider.lastMessageHeight:h])
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
                    
                case .serverError:
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
            
            return .failure(err)
        }
    }
    
    func isChatLoading(with addressRecipient: String) -> Bool {
        return chatsLoading.contains(addressRecipient)
    }
    
    func isChatLoaded(with addressRecipient: String) -> Bool {
        return isChatLoaded[addressRecipient] ?? false
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
                richType: payload.type,
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
            keypair: keypair,
            context: context
        )
        
        return transaction
    }
    
    func removeChatPositon(for address: String) {
        chatPositon.removeValue(forKey: address)
    }
    
    func setChatPositon(for address: String, position: Double?) {
        chatPositon[address] = position
    }
    
    func getChatPositon(for address: String) -> Double? {
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
                richType: payload.type,
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
            keypair: keypair,
            context: context,
            from: chatroom
        )
        
        return transaction
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
        transaction.date = Date() as NSDate
        transaction.recipientId = recipientId
        transaction.senderId = senderId
        transaction.type = Int16(type.rawValue)
        transaction.isOutgoing = true
        transaction.chatMessageId = UUID().uuidString
        transaction.isMarkdown = isMarkdown
        
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
        richContent: [String:String],
        richType: String,
        senderId: String,
        recipientId: String,
        keypair: Keypair,
        context: NSManagedObjectContext,
        from chatroom: Chatroom? = nil
    ) async throws -> ChatTransaction {
        let type = ChatType.richMessage
        
        let transaction = RichMessageTransaction(context: context)
        transaction.date = Date() as NSDate
        transaction.recipientId = recipientId
        transaction.senderId = senderId
        transaction.type = Int16(type.rawValue)
        transaction.isOutgoing = true
        transaction.chatMessageId = UUID().uuidString
        
        transaction.richContent = richContent
        transaction.richType = richType
        
        transaction.transactionStatus = richProviders[richType] != nil ? .notInitiated : nil
        
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
        keypair: Keypair,
        context: NSManagedObjectContext,
        from chatroom: Chatroom? = nil
    ) async throws -> ChatTransaction {
        let type = ChatType.richMessage
        
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
            
            // MARK: 5. Save unconfirmed transaction
            do {
                try context.save()
            } catch {
                throw ChatsProviderError.internalError(error)
            }
            
            let transaction = try await sendTransaction(
                transaction,
                type: type,
                keypair: keypair,
                recipientPublicKey: recipientPublicKey
            )
            
            do {
                transaction.statusEnum = MessageStatus.delivered
                try context.save()
                return transaction
            } catch {
                throw ChatsProviderError.internalError(error)
            }
        } catch {
            guard let error = error as? AccountsProviderResult else {
                throw ChatsProviderError.internalError(error)
            }
            
            switch error {
            case .notFound, .invalidAddress:
                throw ChatsProviderError.accountNotFound(recipientId)
            case .notInitiated, .dummy:
                throw ChatsProviderError.accountNotInitiated(recipientId)
            case .serverError(let error):
                throw ChatsProviderError.serverError(error)
            case .networkError:
                throw ChatsProviderError.networkError
            case .success:
                throw ChatsProviderError.networkError
            }
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
        
        try? privateContext.save()
        
        // MARK: 3. Send
        
        _ = try await sendTransaction(transaction, type: .message, keypair: keypair, recipientPublicKey: recipientPublicKey)
        
        do {
            try privateContext.save()
            return
        } catch {
            throw ChatsProviderError.internalError(error)
        }
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
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        privateContext.delete(privateContext.object(with: message.objectID))
        
        do {
            try privateContext.save()
            return
        } catch {
            throw ChatsProviderError.internalError(error)
        }
    }
    
    // MARK: - Logic
    
    /// Send transaction.
    ///
    /// If success - update transaction's id and add it to unconfirmed transactions.
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
        guard let text = transaction.serializedMessage(), let encodedMessage = adamantCore.encodeMessage(text, recipientPublicKey: recipientPublicKey, privateKey: keypair.privateKey) else {
            throw ChatsProviderError.dependencyError("Failed to encode message")
        }
        
        // MARK: 2. Create
        let signedTransaction = apiService.createSendTransaction(
            senderId: senderId,
            recipientId: recipientId,
            keypair: keypair,
            message: encodedMessage.message,
            type: type,
            nonce: encodedMessage.nonce,
            amount: nil
        )
        
        guard let signedTransaction = signedTransaction else {
            throw ChatsProviderError.internalError(AdamantError(message: AdamantApiService.InternalError.signTransactionFailed.localized))
        }
        
        unconfirmedTransactionsBySignature.append(signedTransaction.signature)
        
        // MARK: 3. Send
        
        do {
            let id = try await apiService.sendTransaction(transaction: signedTransaction)
            
            // Update ID with recieved, add to unconfirmed transactions.
            transaction.transactionId = String(id)
            
            if let index = unconfirmedTransactionsBySignature.firstIndex(
                of: signedTransaction.signature
            ) {
                unconfirmedTransactionsBySignature.remove(at: index)
            }
            
            unconfirmedTransactions[id] = transaction.objectID
                        
            return transaction
        } catch {
            guard let error = error as? ApiServiceError else {
                throw ChatsProviderError.serverError(error)
            }
            
            transaction.statusEnum = MessageStatus.failed
            
            let serviceError: ChatsProviderError
            switch error {
            case .networkError:
                serviceError = .networkError
                
            case .accountNotFound:
                serviceError = .accountNotFound(recipientId)
                
            case .notLogged:
                serviceError = .notLogged
                
            case .serverError(let e):
                serviceError = .serverError(AdamantError(message: e))
                
            case .internalError(let message, _):
                serviceError = ChatsProviderError.internalError(AdamantError(message: message))
                
            case .requestCancelled:
                serviceError = .requestCancelled
            }
            
            throw serviceError
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
    
    nonisolated func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction> {
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
        offset: Int?,
        context: NSManagedObjectContext
    ) async throws {
        if self.accountService.account == nil {
            throw ApiServiceError.accountNotFound
        }
        
        do {
            let transactions = try await apiService.getMessageTransactions(
                address: senderId,
                height: height,
                offset: offset
            )
            
            if transactions.count == 0 {
                return
            }
            
            await process(
                messageTransactions: transactions,
                senderId: senderId,
                privateKey: privateKey,
                context: context
            )
            
            // MARK: 4. Get more transactions
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
                    offset: newOffset,
                    context: context
                )
            }
        } catch {
            self.setState(.failedToUpdate(error), previous: .updating)
            throw error
        }
    }
    
    /// - New unread messagess ids
    private func process(
        messageTransactions: [Transaction],
        senderId: String,
        privateKey: String,
        context: NSManagedObjectContext
    ) async {
        struct DirectionedTransaction {
            let transaction: Transaction
            let isOut: Bool
        }
        
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
                let publicKey = isOut ? transaction?.transaction.recipientPublicKey : transaction?.transaction.senderPublicKey

                let account = try? await accountsProvider.getAccount(byAddress: address, publicKey: publicKey ?? "")
                guard let account = account else { break }
                ids.append(account.objectID)
            }
            
            // Get in our context
            for id in ids {
                if let account = context.object(with: id) as? CoreDataAccount, let address = account.address, let transactions = grouppedTransactions[address] {
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
        var newMessageTransactions = [ChatTransaction]()
        var transactionInProgress: [UInt64] = []
        
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
                   let chatTransaction = transactionService.chatTransaction(
                    from: trs.transaction,
                    isOutgoing: trs.isOut,
                    publicKey: publicKey,
                    privateKey: privateKey,
                    partner: partner,
                    removedMessages: self.removedMessages,
                    context: privateContext
                   ) {
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
        if context.hasChanges {
            do {
                
                try context.save()
                
                // MARK: 6. Update lastTransaction
                let viewContextChatrooms = Set<Chatroom>(partners.keys.compactMap { $0.chatroom }).compactMap { self.stack.container.viewContext.object(with: $0.objectID) as? Chatroom }
                
                viewContextChatrooms.forEach { $0.updateLastTransaction() }
            } catch {
                print(error)
            }
        }
        
        // MARK: 7. Last message height
        if let lastHeight = receivedLastHeight {
            if lastHeight < height {
                updateLastHeight(height: height)
            }
        } else {
            updateLastHeight(height: height)
        }
        
    }
    
    func updateLastHeight(height: Int64) {
        receivedLastHeight = height
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
        
        if blockId.isEmpty {
            transaction.statusEnum = .delivered
        } else {
            self.unconfirmedTransactions.removeValue(forKey: id)
        }
        
        if let lastHeight = receivedLastHeight, lastHeight < height {
            self.receivedLastHeight = height
            transaction.statusEnum = .delivered
            transaction.isConfirmed = true
        }
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
    
    func updateStatus(for transaction: RichMessageTransaction) {
        Task {
            try await richTransactionStatusService.update(
                transaction,
                parentContext: stack.container.viewContext
            )
        }
    }
    
    func markChatAsRead(chatroom: Chatroom) {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        chatroom.markAsReaded()
        try? privateContext.save()
    }
    
    private func onConnectionToTheInternetRestored() {
        onConnectionToTheInternetRestoredTasks.forEach { $0() }
        onConnectionToTheInternetRestoredTasks = []
    }
}

private let requestRepeatDelay: TimeInterval = 2
private let requestRepeatDelayNanoseconds: UInt64 = 2 * 1000000000
