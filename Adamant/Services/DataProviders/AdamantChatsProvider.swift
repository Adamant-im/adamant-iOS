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

class AdamantChatsProvider: ChatsProvider {
    // MARK: Dependencies
    let accountService: AccountService
    let apiService: ApiService
    let socketService: SocketService
    let stack: CoreDataStack
    let adamantCore: AdamantCore
    let accountsProvider: AccountsProvider
    let transactionService: ChatTransactionService
    let securedStore: SecuredStore
    
    private let richProviders: [String: RichMessageProviderWithStatusCheck]
    
    // MARK: Properties
    private(set) var state: State = .empty
    private(set) var receivedLastHeight: Int64?
    private(set) var readedLastHeight: Int64?
    private let apiTransactions = 100
    private var unconfirmedTransactions: [UInt64:NSManagedObjectID] = [:]
    private var unconfirmedTransactionsBySignature: [String] = []
    
    public var chatPositon: [String : Double] = [:]
    private(set) var blockList: [String] = []
    private(set) var removedMessages: [String] = []
    
    public var isChatLoaded: [String : Bool] = [:]
    public var chatMaxMessages: [String : Int] = [:]
    public var chatLoadedMessages: [String : Int] = [:]
    private var chatsLoading: [String] = []
    private let preLoadChatsCount = 5
    private var isConnectedToTheInternet = true
    private var onConnectionToTheInternetRestored: (() -> Void)?
    
    private(set) var isInitiallySynced: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.AdamantChatsProvider.initiallySyncedChanged, object: self, userInfo: [AdamantUserInfoKey.ChatProvider.initiallySynced : isInitiallySynced])
        }
    }
    
    private let processingQueue = DispatchQueue(label: "im.adamant.processing.chat", qos: .utility, attributes: [.concurrent])
    private let sendingQueue = DispatchQueue(label: "im.adamant.sending.chat", qos: .utility, attributes: [.concurrent])
    private let unconfirmedsSemaphore = DispatchSemaphore(value: 1)
    private let highSemaphore = DispatchSemaphore(value: 1)
    private let stateSemaphore = DispatchSemaphore(value: 1)
    
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
        securedStore: SecuredStore
    ) {
        self.accountService = accountService
        self.apiService = apiService
        self.socketService = socketService
        self.stack = stack
        self.adamantCore = adamantCore
        self.accountsProvider = accountsProvider
        self.transactionService = transactionService
        self.securedStore = securedStore
        
        var richProviders = [String: RichMessageProviderWithStatusCheck]()
        for case let provider as RichMessageProviderWithStatusCheck in accountService.wallets {
            richProviders[provider.dynamicRichMessageType] = provider
        }
        self.richProviders = richProviders
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] notification in
            guard let store = self?.securedStore else {
                return
            }
            
            guard let loggedAddress = notification.userInfo?[AdamantUserInfoKey.AccountService.loggedAccountAddress] as? String else {
                store.remove(StoreKey.chatProvider.address)
                store.remove(StoreKey.chatProvider.receivedLastHeight)
                store.remove(StoreKey.chatProvider.readedLastHeight)
                self?.dropStateData()
                return
            }
            
            if let savedAddress: String = store.get(StoreKey.chatProvider.address), savedAddress == loggedAddress {
                if let raw: String = store.get(StoreKey.chatProvider.readedLastHeight), let h = Int64(raw) {
                    self?.readedLastHeight = h
                }
            } else {
                store.remove(StoreKey.chatProvider.receivedLastHeight)
                store.remove(StoreKey.chatProvider.readedLastHeight)
                self?.dropStateData()
                store.set(loggedAddress, for: StoreKey.chatProvider.address)
            }
            
            self?.getChatRooms(offset: nil, completion: nil)
            self?.connectToSocket()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            // Drop everything
            self?.reset()
            
            // BackgroundFetch
            self?.dropStateData()
            
            self?.blockList = []
            self?.removedMessages = []
            
            self?.disconnectFromSocket()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.stayInChanged, object: nil, queue: nil) { [weak self] notification in
            guard let state = notification.userInfo?[AdamantUserInfoKey.AccountService.newStayInState] as? Bool, state else {
                return
            }
            
            if state {
                if let blackList = self?.blockList {
                    self?.securedStore.set(blackList, for: StoreKey.accountService.blackList)
                }
                
                if let removedMessages = self?.removedMessages {
                    self?.securedStore.set(removedMessages, for: StoreKey.accountService.removedMessages)
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            if let previousAppState = self?.previousAppState,
               previousAppState == .background {
                self?.previousAppState = .active
                self?.update()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
            if self?.isInitiallySynced ?? false {
                self?.previousAppState = .background
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let connection = notification
                .userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool
            else {
                return
            }
            
            guard connection == true else {
                self?.isConnectedToTheInternet = false
                return
            }
            
            if self?.isConnectedToTheInternet == false {
                self?.onConnectionToTheInternetRestored?()
                self?.onConnectionToTheInternetRestored = nil
            }
            self?.isConnectedToTheInternet = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Tools
    /// Free stateSemaphore before calling this method, or you will deadlock.
    private func setState(_ state: State, previous prevState: State, notify: Bool = true) {
        stateSemaphore.wait()
        self.state = state
        stateSemaphore.signal()
        
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
        blockList = securedStore.get(StoreKey.accountService.blackList) ?? []
        removedMessages = securedStore.get(StoreKey.accountService.removedMessages) ?? []
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
    
    func getChatRooms(offset: Int?, completion: (() -> Void)?) {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey else {
            completion?()
            return
        }
        
        let prevState = state
        state = .updating
        
        let cms = DispatchSemaphore(value: 1)
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        
        apiGetChatrooms(address: address, offset: offset) { [weak self] chatrooms in
            guard let chatrooms = chatrooms else {
                if let synced = self?.isInitiallySynced, !synced {
                    self?.isInitiallySynced = true
                }
                self?.setState(.upToDate, previous: prevState)
                completion?()
                return
            }
            
            self?.roomsMaxCount = chatrooms.count
            
            if let roomsLoadedCount =  self?.roomsLoadedCount {
                self?.roomsLoadedCount = roomsLoadedCount + (chatrooms.chats?.count ?? 0)
            } else {
                self?.roomsLoadedCount = chatrooms.chats?.count ?? 0
            }
            
            var array = [Transaction]()
            chatrooms.chats?.forEach({ room in
                if let last = room.lastTransaction {
                    array.append(last)
                }
            })
            
            self?.processingQueue.async {
                self?.process(messageTransactions: array,
                              senderId: address,
                              privateKey: privateKey,
                              context: privateContext,
                              contextMutatingSemaphore: cms,
                              completion: {
                    if let synced = self?.isInitiallySynced, !synced {
                        self?.isInitiallySynced = true
                    }
                    self?.setState(.upToDate, previous: prevState)
                    self?.preLoadChats(array, address: address)
                    completion?()
                })
            }
            
        }
    }
    
    func preLoadChats(_ array: [Transaction], address: String) {
        let preLoadChatsCount = preLoadChatsCount
        array.prefix(preLoadChatsCount).forEach { transaction in
            let recipientAddress = transaction.recipientId == address ? transaction.senderId : transaction.recipientId
            getChatMessages(with: recipientAddress, offset: nil, completion: nil)
        }
    }
    
    func apiGetChatrooms(address: String, offset: Int?, completion: ((ChatRooms?) -> Void)?) {
        apiService.getChatRooms(address: address, offset: offset) { [weak self] result in
            switch result {
            case .success(let chatrooms):
                completion?(chatrooms)
            case .failure(let error):
                switch error {
                case .networkError:
                    let getChatrooms: () -> Void = {
                        self?.apiGetChatrooms(
                            address: address,
                            offset: offset,
                            completion: completion
                        )
                    }
                    if self?.isConnectedToTheInternet == true {
                        DispatchQueue.global().asyncAfter(
                            deadline: .now() + requestRepeatDelay,
                            execute: getChatrooms
                        )
                    } else {
                        self?.addOnConnectionToTheInternetRestored(task: getChatrooms)
                    }
                default:
                    completion?(nil)
                }
            }
        }
    }
    
    func getChatMessages(with addressRecipient: String, offset: Int?, completion: (() -> Void)?) {
        guard let address = accountService.account?.address,
              let privateKey = accountService.keypair?.privateKey else {
            completion?()
            return
        }
        
        let cms = DispatchSemaphore(value: 1)
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
      
        if !isChatLoaded.keys.contains(addressRecipient) {
            chatsLoading.append(addressRecipient)
        }
        apiGetChatMessages(address: address, addressRecipient: addressRecipient, offset: offset) { [weak self] chatroom in
            self?.processingQueue.async {
                self?.isChatLoaded[addressRecipient] = true
                self?.chatMaxMessages[addressRecipient] = chatroom?.count ?? 0
                let loadedCount = self?.chatLoadedMessages[addressRecipient] ?? 0
                self?.chatLoadedMessages[addressRecipient] = loadedCount + (chatroom?.messages?.count ?? 0)
                if let index = self?.chatsLoading.firstIndex(of: addressRecipient) {
                    self?.chatsLoading.remove(at: index)
                }
                guard let transactions = chatroom?.messages,
                      transactions.count > 0 else {
                    completion?()
                    return
                }
                self?.process(messageTransactions: transactions,
                              senderId: address,
                              privateKey: privateKey,
                              context: privateContext,
                              contextMutatingSemaphore: cms,
                              completion: {
                    completion?()
                    NotificationCenter.default.post(name: .AdamantChatsProvider.initiallyLoadedMessages, object: addressRecipient)
                })
            }
        }
    }
    
    func apiGetChatMessages(address: String, addressRecipient: String, offset: Int?, completion: ((ChatRooms?) -> Void)?) {
        apiService.getChatMessages(address: address, addressRecipient: addressRecipient, offset: offset) { [weak self] result in
            switch result {
            case .success(let chatroom):
                completion?(chatroom)
            case .failure(let error):
                switch error {
                case .networkError:
                    let getChatMessages: () -> Void = {
                        self?.apiGetChatMessages(
                            address: address,
                            addressRecipient: addressRecipient,
                            offset: offset,
                            completion: completion
                        )
                    }
                    if self?.isConnectedToTheInternet == true {
                        DispatchQueue.global().asyncAfter(
                            deadline: .now() + requestRepeatDelay,
                            execute: getChatMessages
                        )
                    } else {
                        self?.addOnConnectionToTheInternetRestored(task: getChatMessages)
                    }
                default:
                    completion?(nil)
                }
            }
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
        let cms = DispatchSemaphore(value: 1)
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        
        socketService.connect(address: address) { [weak self] result in
            switch result {
            case .success(let trans):
                self?.processingQueue.async {
                    self?.process(messageTransactions: [trans],
                                 senderId: address,
                                 privateKey: privateKey,
                                 context: privateContext,
                                 contextMutatingSemaphore: cms)
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
        if state == .updating {
            completion?(nil)
            return
        }
        
        stateSemaphore.wait()
        // MARK: 1. Check state
        if state == .updating {
            stateSemaphore.signal()
            completion?(nil)
            return
        }
        
        // MARK: 2. Prepare
        let prevState = state
        
        guard let address = accountService.account?.address, let privateKey = accountService.keypair?.privateKey else {
            stateSemaphore.signal()
            setState(.failedToUpdate(ChatsProviderError.notLogged), previous: prevState)
            completion?(.failure(ChatsProviderError.notLogged))
            return
        }
        
        state = .updating
        stateSemaphore.signal()
        
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        let processingGroup = DispatchGroup()
        let cms = DispatchSemaphore(value: 1)
        let prevHeight = receivedLastHeight
        getTransactions(senderId: address, privateKey: privateKey, height: receivedLastHeight, offset: nil, dispatchGroup: processingGroup, context: privateContext, contextMutatingSemaphore: cms)
        
        // MARK: 4. Check
        processingGroup.notify(queue: DispatchQueue.global(qos: .utility)) { [weak self] in
            guard let state = self?.state else {
                completion?(.failure(.dependencyError("Updating")))
                return
            }
            
            switch state {
            case .upToDate, .empty, .updating:
                self?.setState(.upToDate, previous: prevState)
                
                if prevHeight != self?.receivedLastHeight, let h = self?.receivedLastHeight {
                    NotificationCenter.default.post(name: Notification.Name.AdamantChatsProvider.newUnreadMessages,
                                                    object: self,
                                                    userInfo: [AdamantUserInfoKey.ChatProvider.lastMessageHeight:h])
                }
                
                if let h = self?.receivedLastHeight {
                    self?.readedLastHeight = h
                } else {
                    self?.readedLastHeight = 0
                }
                
                if let store = self?.securedStore {
                    if let h = self?.receivedLastHeight {
                        store.set(String(h), for: StoreKey.chatProvider.receivedLastHeight)
                    }
                    
                    if let h = self?.readedLastHeight, h > 0 {
                        store.set(String(h), for: StoreKey.chatProvider.readedLastHeight)
                    }
                }
                
                if let synced = self?.isInitiallySynced, !synced {
                    self?.isInitiallySynced = true
                }
                
                completion?(.success)
                
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
                
                completion?(.failure(err))
            }
        }
    }
    
    func isChatLoading(with addressRecipient: String) -> Bool {
        return chatsLoading.contains(addressRecipient)
    }
}

// MARK: - Sending messages {
extension AdamantChatsProvider {
    func sendMessage(_ message: AdamantMessage, recipientId: String, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        guard loggedAccount.balance >= message.fee else {
            completion(.failure(.notEnoughMoneyToSend))
            return
        }
        
        switch validateMessage(message) {
        case .isValid:
            break
            
        case .empty:
            completion(.failure(.messageNotValid(.empty)))
            return
            
        case .tooLong:
            completion(.failure(.messageNotValid(.tooLong)))
            return
        }
        
        sendingQueue.async {
            switch message {
            case .text(let text):
                self.sendTextMessage(text: text, isMarkdown: false, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, type: message.chatType, completion: completion)
                
            case .markdownText(let text):
                self.sendTextMessage(text: text, isMarkdown: true, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, type: message.chatType, completion: completion)
                
            case .richMessage(let payload):
                self.sendRichMessage(richContent: payload.content(), richType: payload.type, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, completion: completion)
            }
        }
    }
    
    func sendMessage(_ message: AdamantMessage, recipientId: String, from chatroom: Chatroom?, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        guard loggedAccount.balance >= message.fee else {
            completion(.failure(.notEnoughMoneyToSend))
            return
        }
        
        switch validateMessage(message) {
        case .isValid:
            break
            
        case .empty:
            completion(.failure(.messageNotValid(.empty)))
            return
            
        case .tooLong:
            completion(.failure(.messageNotValid(.tooLong)))
            return
        }
        
        sendingQueue.async {
            switch message {
            case .text(let text):
                self.sendTextMessage(text: text, isMarkdown: false, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, type: message.chatType, from: chatroom, completion: completion)
                
            case .markdownText(let text):
                self.sendTextMessage(text: text, isMarkdown: true, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, type: message.chatType, from: chatroom, completion: completion)
                
            case .richMessage(let payload):
                self.sendRichMessage(richContent: payload.content(), richType: payload.type, senderId: loggedAccount.address, recipientId: recipientId, keypair: keypair, from: chatroom, completion: completion)
            }
        }
    }
    
    private func sendTextMessage(text: String, isMarkdown: Bool, senderId: String, recipientId: String, keypair: Keypair, type: ChatType, from chatroom: Chatroom? = nil, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        let transaction = MessageTransaction(context: context)
        transaction.date = Date() as NSDate
        transaction.recipientId = recipientId
        transaction.senderId = senderId
        transaction.type = Int16(type.rawValue)
        transaction.isOutgoing = true
        transaction.chatMessageId = UUID().uuidString
        transaction.isMarkdown = isMarkdown
        
        transaction.message = text
        
        if let c = chatroom, let chatroom = context.object(with: c.objectID) as? Chatroom, let partner = chatroom.partner {
            transaction.statusEnum = MessageStatus.pending
            transaction.partner = context.object(with: partner.objectID) as? BaseAccount
            
            chatroom.addToTransactions(transaction)
            
            do {
                try context.save()
                completion(.success(transaction: transaction))
            } catch {
                completion(.failure(.internalError(error)))
                return
            }
        }
        
        prepareAndSendChatTransaction(transaction, in: context, recipientId: recipientId, type: type, keypair: keypair, from: chatroom, completion: completion)
    }
    
    private func sendRichMessage(richContent: [String:String], richType: String, senderId: String, recipientId: String, keypair: Keypair, from chatroom: Chatroom? = nil, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
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
        
        if let c = chatroom, let chatroom = context.object(with: c.objectID) as? Chatroom, let partner = chatroom.partner {
            transaction.statusEnum = MessageStatus.pending
            transaction.partner = context.object(with: partner.objectID) as? BaseAccount
            
            chatroom.addToTransactions(transaction)
            
            do {
                try context.save()
                completion(.success(transaction: transaction))
            } catch {
                completion(.failure(.internalError(error)))
                return
            }
        }
        
        prepareAndSendChatTransaction(transaction, in: context, recipientId: recipientId, type: type, keypair: keypair, from: chatroom, completion: completion)
    }
    
    /// Transaction must be in passed context
    private func prepareAndSendChatTransaction(_ transaction: ChatTransaction, in context: NSManagedObjectContext, recipientId: String, type: ChatType, keypair: Keypair, from chatroom: Chatroom? = nil, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
        // MARK: 1. Get account
        let accountsGroup = DispatchGroup()
        accountsGroup.enter()
        
        var result: AccountsProviderResult! = nil
        accountsProvider.getAccount(byAddress: recipientId) { r in
            result = r
            accountsGroup.leave()
        }
        
        accountsGroup.wait()
        
        let recipientAccount: CoreDataAccount
        switch result! {
        case .success(let account):
            recipientAccount = account
            
        case .notFound, .invalidAddress:
            completion(.failure(.accountNotFound(recipientId)))
            return
            
        case .notInitiated, .dummy:
            completion(.failure(.accountNotInitiated(recipientId)))
            return
            
        case .serverError(let error):
            completion(.failure(.serverError(error)))
            return
            
        case .networkError:
            completion(.failure(ChatsProviderError.networkError))
            return
        }
        
        guard let recipientPublicKey = recipientAccount.publicKey else {
            completion(.failure(.accountNotFound(recipientId)))
            return
        }
        
        let isAdded = chatroom == nil
        
        // MARK: 2. Get Chatroom
        guard let id = recipientAccount.chatroom?.objectID, let chatroom = context.object(with: id) as? Chatroom else {
            completion(.failure(.accountNotFound(recipientId)))
            return
        }
        
        // MARK: 3. Prepare transaction
        transaction.statusEnum = MessageStatus.pending
        transaction.partner = context.object(with: recipientAccount.objectID) as? BaseAccount
        
        if isAdded {
            chatroom.addToTransactions(transaction)
        }
        
        // MARK: 4. Last in
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
        
        // MARK: 5. Save unconfirmed transaction
        do {
            try context.save()
        } catch {
            completion(.failure(.internalError(error)))
            return
        }
        
        // MARK: 6. Send
        sendTransaction(transaction, type: type, keypair: keypair, recipientPublicKey: recipientPublicKey) { result in
            switch result {
            case .success(let transaction):
                do {
                    transaction.statusEnum = MessageStatus.delivered
                    try context.save()
                    completion(.success(transaction: transaction))
                } catch {
                    completion(.failure(.internalError(error)))
                }
                
            case .failure(let error):
                try? context.save()
                completion(.failure(error))
            }
        }
    }
    
    func retrySendMessage(_ message: ChatTransaction, completion: @escaping (ChatsProviderRetryCancelResult) -> Void) {
        // MARK: 0. Prepare
        switch message.statusEnum {
        case .delivered, .pending:
            completion(.invalidTransactionStatus(message.statusEnum))
            return
            
        case .failed:
            break
        }
        
        guard let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        guard let recipientPublicKey = message.chatroom?.partner?.publicKey else {
            completion(.failure(.accountNotFound(message.recipientId ?? "")))
            return
        }
        
        // MARK: 1. Prepare private context
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        guard let transaction = privateContext.object(with: message.objectID) as? MessageTransaction else {
            completion(.failure(.notLogged)) //
            return
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
        sendTransaction(transaction, type: .message, keypair: keypair, recipientPublicKey: recipientPublicKey) { result in
            switch result {
            case .success:
                do {
                    try privateContext.save()
                    completion(.success)
                } catch {
                    completion(.failure(.internalError(error)))
                }
                
            case .failure(let error):
                try? privateContext.save()
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Delete local message
    func cancelMessage(_ message: ChatTransaction, completion: @escaping (ChatsProviderRetryCancelResult) -> Void) {
        // MARK: 0. Prepare
        switch message.statusEnum {
        case .delivered, .pending:
            // We can't cancel sent transactions
            completion(.invalidTransactionStatus(message.statusEnum))
            return
            
        case .failed:
            break
        }
        
        // MARK: 1. Find. Destroy. Save.
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        
        privateContext.delete(privateContext.object(with: message.objectID))
        
        do {
            try privateContext.save()
            completion(.success)
        } catch {
            completion(.failure(.internalError(error)))
            return
        }
    }
    
    // MARK: - Logic
    
    /// Send transaction.
    ///
    /// If success - update transaction's id and add it to unconfirmed transactions.
    /// If fails - set transaction status to .failed
    private func sendTransaction(_ transaction: ChatTransaction, type: ChatType, keypair: Keypair, recipientPublicKey: String, completion: @escaping (ChatsProviderResultWithTransaction) -> Void) {
        // MARK: 0. Prepare
        guard let senderId = transaction.senderId,
            let recipientId = transaction.recipientId else {
            completion(.failure(.accountNotFound(recipientPublicKey)))
                return
        }
        
        // MARK: 1. Encode
        guard let text = transaction.serializedMessage(), let encodedMessage = adamantCore.encodeMessage(text, recipientPublicKey: recipientPublicKey, privateKey: keypair.privateKey) else {
            completion(.failure(.dependencyError("Failed to encode message")))
            return
        }
        
        // MARK: 3. Send
        var signedTransaction: UnregisteredTransaction?
        signedTransaction = apiService.sendMessage(
            senderId: senderId,
            recipientId: recipientId,
            keypair: keypair,
            message: encodedMessage.message,
            type: type,
            nonce: encodedMessage.nonce,
            amount: nil
        ) { [weak self] result in
            switch result {
            case .success(let id):
                // Update ID with recieved, add to unconfirmed transactions.
                transaction.transactionId = String(id)
                
                self?.unconfirmedsSemaphore.wait()
                if
                    let signedTransaction = signedTransaction,
                    let index = self?.unconfirmedTransactionsBySignature.firstIndex(
                        of: signedTransaction.signature
                    )
                {
                    self?.unconfirmedTransactionsBySignature.remove(at: index)
                }
                DispatchQueue.main.sync {
                    self?.unconfirmedTransactions[id] = transaction.objectID
                }
                self?.unconfirmedsSemaphore.signal()
                
                completion(.success(transaction: transaction))
                
            case .failure(let error):
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
                
                completion(.failure(serviceError))
            }
        }
        
        signedTransaction.map { unconfirmedTransactionsBySignature.append($0.signature) }
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
    
    func getChatController(for chatroom: Chatroom) -> NSFetchedResultsController<ChatTransaction> {
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
    private func getTransactions(senderId: String,
                                 privateKey: String,
                                 height: Int64?,
                                 offset: Int?,
                                 dispatchGroup: DispatchGroup,
                                 context: NSManagedObjectContext,
                                 contextMutatingSemaphore cms: DispatchSemaphore) {
        // Enter 1
        dispatchGroup.enter()
        
        // MARK: 1. Get new transactions
        apiService.getMessageTransactions(address: senderId, height: height, offset: offset) { result in
            defer {
                // Leave 1
                dispatchGroup.leave()
            }
            
            if self.accountService.account == nil {
                return
            }
            
            switch result {
            case .success(let transactions):
                if transactions.count == 0 {
                    return
                }
                
                // MARK: 2. Process transactions in background
                // Enter 2
                dispatchGroup.enter()
                self.processingQueue.async {
                    defer {
                        // Leave 2
                        dispatchGroup.leave()
                    }
                    
                    self.process(messageTransactions: transactions,
                                 senderId: senderId,
                                 privateKey: privateKey,
                                 context: context,
                                 contextMutatingSemaphore: cms)
                }
                
                // MARK: 4. Get more transactions
                if transactions.count == self.apiTransactions {
                    let newOffset: Int
                    if let offset = offset {
                        newOffset = offset + self.apiTransactions
                    } else {
                        newOffset = self.apiTransactions
                    }
                    
                    self.getTransactions(senderId: senderId, privateKey: privateKey, height: height, offset: newOffset, dispatchGroup: dispatchGroup, context: context, contextMutatingSemaphore: cms)
                }
                
            case .failure(let error):
                self.setState(.failedToUpdate(error), previous: .updating)
            }
        }
    }
    
    /// - Returns: New unread messagess ids
    private func process(messageTransactions: [Transaction],
                         senderId: String,
                         privateKey: String,
                         context: NSManagedObjectContext,
                         contextMutatingSemaphore: DispatchSemaphore,
                         completion: (() -> Void)? = nil) {
        struct DirectionedTransaction {
            let transaction: Transaction
            let isOut: Bool
        }
        
        // MARK: 1. Gather partner keys
        let mapped = messageTransactions.map({ DirectionedTransaction(transaction: $0, isOut: $0.senderId == senderId) })
        let grouppedTransactions = Dictionary(grouping: mapped, by: { $0.isOut ? $0.transaction.recipientId : $0.transaction.senderId })
        
        // MARK: 2. Gather Accounts
        var partners: [CoreDataAccount:[DirectionedTransaction]] = [:]
        
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
            let semaphore = DispatchSemaphore(value: 1)
            let keysGroup = DispatchGroup()
            for address in notFound {
                keysGroup.enter() // Enter 1
                
                let transaction = grouppedTransactions[address]?.first
                let isOut = transaction?.isOut ?? false
                let publicKey = isOut ? transaction?.transaction.recipientPublicKey : transaction?.transaction.senderPublicKey

                accountsProvider.getAccount(byAddress: address, publicKey: publicKey ?? "") { result in
                    defer {
                        keysGroup.leave() // Exit 1
                    }
                    
                    if case let .success(account) = result {
                        semaphore.wait()
                        ids.append(account.objectID)
                        semaphore.signal()
                    }
                }
            }
            
            keysGroup.wait()
            
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
                unconfirmedsSemaphore.wait()
                defer { unconfirmedsSemaphore.signal() }
                
                transactionInProgress.append(trs.transaction.id)
                if let objectId = unconfirmedTransactions[trs.transaction.id], let unconfirmed = context.object(with: objectId) as? ChatTransaction {
                    confirmTransaction(unconfirmed, id: trs.transaction.id, height: Int64(trs.transaction.height), blockId: trs.transaction.blockId, confirmations: trs.transaction.confirmations)
                    
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
                
                if let partner = privateContext.object(with: account.objectID) as? BaseAccount, let chatTransaction = transactionService.chatTransaction(from: trs.transaction, isOutgoing: trs.isOut, publicKey: publicKey, privateKey: privateKey, partner: partner, removedMessages: self.removedMessages, context: privateContext) {
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
                defer {
                    contextMutatingSemaphore.signal()
                }
                
                contextMutatingSemaphore.wait()
                
                try privateContext.save()
            } catch {
                print(error)
            }
        }
        
        // MARK: 6. Save to main!
        if context.hasChanges {
            do {
                defer {
                    contextMutatingSemaphore.signal()
                }
                contextMutatingSemaphore.wait()
                
                try context.save()
                
                // MARK: 6. Update lastTransaction
                let viewContextChatrooms = Set<Chatroom>(partners.keys.compactMap { $0.chatroom }).compactMap { self.stack.container.viewContext.object(with: $0.objectID) as? Chatroom }
                
                DispatchQueue.main.async {
                    viewContextChatrooms.forEach { $0.updateLastTransaction() }
                    self.transactionService.processingComplete(transactionInProgress)
                }
            } catch {
                print(error)
            }
        }
        
        // MARK: 7. Last message height
        highSemaphore.wait()
        if let lastHeight = receivedLastHeight {
            if lastHeight < height {
                self.receivedLastHeight = height
            }
        } else {
            receivedLastHeight = height
        }
        highSemaphore.signal()
        completion?()
    }
}

// MARK: - Tools
extension AdamantChatsProvider {
    func addUnconfirmed(transactionId id: UInt64, managedObjectId: NSManagedObjectID) {
        unconfirmedsSemaphore.wait()
        
        DispatchQueue.main.sync {
            self.unconfirmedTransactions[id] = managedObjectId
        }
        
        unconfirmedsSemaphore.signal()
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
    
    public func blockChat(with address: String) {
        if !self.blockList.contains(address) {
            self.blockList.append(address)
            
            if self.accountService.hasStayInAccount {
                self.securedStore.set(blockList, for: StoreKey.accountService.blackList)
            }
        }
    }
    
    public func removeMessage(with id: String) {
        if !self.removedMessages.contains(id) {
            self.removedMessages.append(id)
            
            if self.accountService.hasStayInAccount {
                self.securedStore.set(removedMessages, for: StoreKey.accountService.removedMessages)
            }
        }
    }
    
    private func addOnConnectionToTheInternetRestored(task: @escaping () -> Void) {
        onConnectionToTheInternetRestored = { [onConnectionToTheInternetRestored] in
            onConnectionToTheInternetRestored?()
            task()
        }
    }
}

private let requestRepeatDelay: TimeInterval = 2
