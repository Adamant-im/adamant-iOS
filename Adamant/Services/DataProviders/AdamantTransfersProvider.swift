//
//  AdamantTransfersProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

actor AdamantTransfersProvider: TransfersProvider {
    // MARK: Constants
    static let transferFee: Decimal = Decimal(sign: .plus, exponent: -1, significand: 5)
    
    // MARK: Dependencies
    let apiService: ApiService
    private let stack: CoreDataStack
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    private let accountsProvider: AccountsProvider
    let securedStore: SecuredStore
    private let transactionService: ChatTransactionService
    weak var chatsProvider: ChatsProvider?
    
    private(set) var state: State = .empty
    private(set) var isInitiallySynced: Bool = false
    private(set) var receivedLastHeight: Int64?
    private(set) var readedLastHeight: Int64?
    private(set) var hasTransactions: Bool = false
    private let apiTransactions = 100
    
    private var unconfirmedTransactions: [UInt64:NSManagedObjectID] = [:]
    
    // MARK: Tools
    
    /// Free stateSemaphore before calling this method, or you will deadlock.
    private func setState(_ state: State, previous prevState: State, notify: Bool = true) {
        self.state = state
        
        if notify {
            switch prevState {
            case .failedToUpdate:
                NotificationCenter.default.post(name: Notification.Name.AdamantTransfersProvider.stateChanged, object: nil, userInfo: [AdamantUserInfoKey.TransfersProvider.newState: state,
                                                                                                                     AdamantUserInfoKey.TransfersProvider.prevState: prevState])
                
            default:
                if prevState != self.state {
                    NotificationCenter.default.post(name: Notification.Name.AdamantTransfersProvider.stateChanged, object: nil, userInfo: [AdamantUserInfoKey.TransfersProvider.newState: state,
                                                                                                                         AdamantUserInfoKey.TransfersProvider.prevState: prevState])
                }
            }
        }
    }
    
    // MARK: Lifecycle
    init(
        apiService: ApiService,
        stack: CoreDataStack,
        adamantCore: AdamantCore,
        accountService: AccountService,
        accountsProvider: AccountsProvider,
        securedStore: SecuredStore,
        transactionService: ChatTransactionService
    ) {
        self.apiService = apiService
        self.stack = stack
        self.adamantCore = adamantCore
        self.accountService = accountService
        self.accountsProvider = accountsProvider
        self.securedStore = securedStore
        self.transactionService = transactionService
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] notification in
            guard let store = self?.securedStore else {
                return
            }
            
            guard let loggedAddress = notification.userInfo?[AdamantUserInfoKey.AccountService.loggedAccountAddress] as? String else {
                store.remove(StoreKey.transfersProvider.address)
                store.remove(StoreKey.transfersProvider.receivedLastHeight)
                store.remove(StoreKey.transfersProvider.readedLastHeight)
                self?.dropStateData()
                return
            }
            
            if let savedAddress: String = store.get(StoreKey.transfersProvider.address), savedAddress == loggedAddress {
                if let raw: String = store.get(StoreKey.transfersProvider.readedLastHeight), let h = Int64(raw) {
                    self?.readedLastHeight = h
                }
            } else {
                store.remove(StoreKey.transfersProvider.receivedLastHeight)
                store.remove(StoreKey.transfersProvider.readedLastHeight)
                self?.dropStateData()
                store.set(loggedAddress, for: StoreKey.transfersProvider.address)
            }
            
            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            // Drop everything
            self?.reset()
            
            // BackgroundFetch
            self?.dropStateData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setChatsProvider(_ chatsProvider: ChatsProvider?) {
        self.chatsProvider = chatsProvider
    }
}

// MARK: - DataProvider
extension AdamantTransfersProvider {
    func reload() {
        reset(notify: false)
        update()
    }
    
    func update() {
        self.update(completion: nil)
    }
    
    func update(completion: ((TransfersProviderResult?) -> Void)?) {
        Task {
            let result = await update()
            completion?(result)
        }
    }
    
    func update() async -> TransfersProviderResult? {
        if state == .updating {
            return nil
        }
        
        let prevState = state
        state = .updating
        
        guard let address = accountService.account?.address else {
            self.setState(.failedToUpdate(TransfersProviderError.notLogged), previous: prevState)
            return .failure(TransfersProviderError.notLogged)
        }
        
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = stack.container.viewContext
        let processingGroup = DispatchGroup()
        let cms = DispatchSemaphore(value: 1)
        let prevHeight = receivedLastHeight
        
        getTransactions(forAccount: address, type: .send, fromHeight: prevHeight, offset: nil, dispatchGroup: processingGroup, context: privateContext, contextMutatingSemaphore: cms)
        
        // MARK: 4. Check
        
        switch state {
        case .empty, .updating, .upToDate:
            setState(.upToDate, previous: prevState)
            
            if prevHeight != receivedLastHeight,
               let h = receivedLastHeight {
                NotificationCenter.default.post(name: Notification.Name.AdamantChatsProvider.newUnreadMessages,
                                                object: self,
                                                userInfo: [AdamantUserInfoKey.TransfersProvider.lastTransactionHeight:h])
            }
            
            if let h = receivedLastHeight {
                readedLastHeight = h
            } else {
                readedLastHeight = 0
            }
            
            let store = securedStore
            // Received
            if let h = receivedLastHeight {
                if
                    let raw: String = store.get(StoreKey.transfersProvider.receivedLastHeight),
                    let prev = Int64(raw)
                {
                    if h > prev {
                        store.set(String(h), for: StoreKey.transfersProvider.receivedLastHeight)
                    }
                } else {
                    store.set(String(h), for: StoreKey.transfersProvider.receivedLastHeight)
                }
            }
            
            // Readed
            if let h = readedLastHeight {
                if
                    let raw: String = store.get(StoreKey.transfersProvider.readedLastHeight),
                    let prev = Int64(raw)
                {
                    if h > prev {
                        store.set(String(h), for: StoreKey.transfersProvider.readedLastHeight)
                    }
                } else {
                    store.set(String(h), for: StoreKey.transfersProvider.readedLastHeight)
                }
            }
            
            if !isInitiallySynced {
                isInitiallySynced = true
                NotificationCenter.default.post(name: Notification.Name.AdamantTransfersProvider.initialSyncFinished, object: self)
            }
            
            return .success
            
        case .failedToUpdate(let error): // Processing failed
            let err: TransfersProviderError
            
            switch error {
            case let error as ApiServiceError:
                switch error {
                case .notLogged:
                    err = .notLogged
                    
                case .accountNotFound:
                    err = .accountNotFound(address: address)
                    
                case .serverError:
                    err = .serverError(error)
                    
                case .internalError(let message, _):
                    err = .dependencyError(message: message)
                    
                case .networkError:
                    err = .networkError
                    
                case .requestCancelled:
                    err = .requestCancelled
                }
                
            default:
                err = TransfersProviderError.internalError(message: String.adamantLocalized.sharedErrors.internalError(message: error.localizedDescription), error: error)
            }
            
            return .failure(err)
        }
    }
    
    func reset() {
        reset(notify: true)
    }
    
    private func reset(notify: Bool) {
        hasTransactions = false
        isInitiallySynced = false
        let prevState = self.state
        setState(.updating, previous: prevState, notify: false)    // Block update calls
        
        // Drop props
        receivedLastHeight = nil
        readedLastHeight = nil
        
        // Drop store
        securedStore.remove(StoreKey.transfersProvider.address)
        securedStore.remove(StoreKey.transfersProvider.receivedLastHeight)
        securedStore.remove(StoreKey.transfersProvider.readedLastHeight)
        
        // Drop CoreData
//        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
//        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        context.parent = stack.container.viewContext
//
//        if let result = try? context.fetch(request) {
//            for obj in result {
//                context.delete(obj)
//            }
//
//            try? context.save()
//        }
        
        // Set state
        setState(.empty, previous: prevState, notify: notify)
    }
}

// MARK: - TransfersProvider
extension AdamantTransfersProvider {
    // MARK: Controllers
    func transfersController() -> NSFetchedResultsController<TransferTransaction> {
        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false),
                                   NSSortDescriptor(key: "transactionId", ascending: false)]
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return controller
    }
    
    func transfersController(for account: CoreDataAccount) -> NSFetchedResultsController<TransferTransaction> {
        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false),
                                   NSSortDescriptor(key: "transactionId", ascending: false)]
        request.predicate = NSPredicate(format: "partner = %@", account)
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try! controller.performFetch()
        return controller
    }
    
    func unreadTransfersController() -> NSFetchedResultsController<TransferTransaction> {
        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
        request.predicate = NSPredicate(format: "isUnread == true")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false),
                                   NSSortDescriptor(key: "transactionId", ascending: false)]
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return controller
    }
    
    // MARK: Sending Funds
    
    // Wrapper
    func transferFunds(toAddress recipient: String, amount: Decimal, comment: String?, completion: @escaping (TransfersProviderTransferResult) -> Void) {
        if let comment = comment, comment.count > 0 {
            self.transferFundsInternal(toAddress: recipient, amount: amount, comment: comment, completion: completion)
        } else {
            self.transferFundsInternal(toAddress: recipient, amount: amount, completion: completion)
        }
    }
    
    private func transferFundsInternal(toAddress recipient: String, amount: Decimal, comment: String, completion: @escaping (TransfersProviderTransferResult) -> Void) {
        // MARK: 0. Prepare
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        guard loggedAccount.balance > amount + Self.transferFee else {
            completion(.failure(.notEnoughMoney))
            return
        }
        
        // MARK: 1. Get recipient
        let accountsGroup = DispatchGroup()
        accountsGroup.enter()
        
        var result: AccountsProviderResult! = nil
        accountsProvider.getAccount(byAddress: recipient) { r in
            result = r
            accountsGroup.leave()
        }
        
        accountsGroup.wait()
        
        let recipientAccount: CoreDataAccount
        switch result! {
        case .success(let account):
            recipientAccount = account
            
        case .notFound, .invalidAddress, .notInitiated, .dummy:
            completion(.failure(.accountNotFound(address: recipient)))
            return
            
        case .serverError(let error):
            completion(.failure(.serverError(error)))
            return
            
        case .networkError:
            completion(.failure(.networkError))
            return
        }
        
        guard let recipientPublicKey = recipientAccount.publicKey else {
            completion(.failure(.accountNotFound(address: recipient)))
            return
        }
        
        // MARK: 2. Chatroom
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        guard let id = recipientAccount.chatroom?.objectID,
            let chatroom = context.object(with: id) as? Chatroom,
            let partner = context.object(with: recipientAccount.objectID) as? BaseAccount else {
            completion(.failure(.accountNotFound(address: recipient)))
            return
        }
        
        // MARK: 3. Transaction
        let transaction = TransferTransaction(context: context)
        transaction.amount = amount as NSDecimalNumber
        transaction.date = Date() as NSDate
        transaction.recipientId = recipient
        transaction.senderId = loggedAccount.address
        transaction.type = Int16(TransactionType.chatMessage.rawValue)
        transaction.isOutgoing = true
        transaction.showsChatroom = true
        transaction.chatMessageId = UUID().uuidString
        transaction.statusEnum = MessageStatus.pending
        transaction.comment = comment
        transaction.fee = Self.transferFee as NSDecimalNumber
        transaction.partner = partner
        
        chatroom.addToTransactions(transaction)
        
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
            completion(.failure(.internalError(message: String.adamantLocalized.sharedErrors.unknownError, error: error)))
            return
        }
        
        // MARK: 6. Encode
        guard let encodedMessage = adamantCore.encodeMessage(comment, recipientPublicKey: recipientPublicKey, privateKey: keypair.privateKey) else {
            completion(.failure(.internalError(message: "Failed to encode message", error: nil)))
            return
        }
        
        // MARK: 7. Send
        apiService.sendMessage(senderId: loggedAccount.address, recipientId: recipient, keypair: keypair, message: encodedMessage.message, type: ChatType.message, nonce: encodedMessage.nonce, amount: amount) { [weak self] result in
            switch result {
            case .success(let id):
                transaction.transactionId = String(id)
                
                Task { [weak self] in
                    await self?.chatsProvider?.addUnconfirmed(transactionId: id, managedObjectId: transaction.objectID)
                }
                
                do {
                    try context.save()
                } catch {
                    completion(.failure(.internalError(message: String.adamantLocalized.sharedErrors.unknownError, error: error)))
                    break
                }
                
                if let trs = self?.stack.container.viewContext.object(with: transaction.objectID) as? TransferTransaction {
                    completion(.success(transaction: trs))
                } else {
                    completion(.failure(.internalError(message: "Failed to get transaction in viewContext", error: nil)))
                }
                
            case .failure(let error):
                transaction.statusEnum = MessageStatus.failed
                try? context.save()
                
                completion(.failure(.serverError(error)))
            }
        }
    }
    
    private func transferFundsInternal(toAddress recipient: String, amount: Decimal, completion: @escaping (TransfersProviderTransferResult) -> Void) {
        // MARK: 0. Prepare
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
        
        guard loggedAccount.balance > amount + Self.transferFee else {
            completion(.failure(.notEnoughMoney))
            return
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        // MARK: 1. Get recipient
        let accountsGroup = DispatchGroup()
        accountsGroup.enter() // Enter 1
        
        var recipientAccount: BaseAccount?
        var providerError: TransfersProviderError?
        
        accountsProvider.getAccount(byAddress: recipient) { result in
            defer {
                accountsGroup.leave() // Exit 1
            }
            
            switch result {
            case .success(let account):
                recipientAccount = account
                
            case .dummy(let account):
                recipientAccount = account
                
            case .notFound, .notInitiated:
                accountsGroup.enter() // Enter 2, before exit 1
                self.accountsProvider.getDummyAccount(for: recipient) { result in
                    defer {
                        accountsGroup.leave() // Exit 2
                    }
                    
                    switch result {
                    case .success(let dummy):
                        recipientAccount = dummy
                        
                    case .foundRealAccount(let account):
                        recipientAccount = account
                        
                    case .invalidAddress(let address):
                        providerError = .accountNotFound(address: address)
                        
                    case .internalError(let error):
                        providerError = TransfersProviderError.internalError(message: error.localizedDescription, error: error)
                    }
                }
                
            case .invalidAddress:
                providerError = .accountNotFound(address: recipient)
                
            case .serverError(let error):
                providerError = .serverError(error)
                
            case .networkError:
                providerError = .networkError
            }
        }
        
        accountsGroup.wait()
        
        let backgroundAccount: BaseAccount
        if let acc = recipientAccount, let obj = context.object(with: acc.objectID) as? BaseAccount {
            backgroundAccount = obj
        } else {
            if let err = providerError {
                completion(.failure(err))
            } else {
                completion(.failure(.accountNotFound(address: recipient)))
            }
            
            return
        }
        
        // MARK: 2. Create transaction
        let transaction = TransferTransaction(context: context)
        transaction.amount = amount as NSDecimalNumber
        transaction.date = Date() as NSDate
        transaction.recipientId = recipient
        transaction.senderId = loggedAccount.address
        transaction.type = Int16(TransactionType.send.rawValue)
        transaction.isOutgoing = true
        transaction.showsChatroom = false
        transaction.fee = Self.transferFee as NSDecimalNumber
        
        transaction.transactionId = nil
        transaction.blockId = nil
        transaction.chatMessageId = UUID().uuidString
        transaction.statusEnum = MessageStatus.pending
        
        // MARK: 3. Chatroom
        backgroundAccount.addToTransfers(transaction)
        
        if let coreDataAccount = backgroundAccount as? CoreDataAccount, let id = coreDataAccount.chatroom?.objectID, let chatroom = context.object(with: id) as? Chatroom {
            chatroom.addToTransactions(transaction)
            
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
        
        // MARK: 4. Save unconfirmed transaction
        do {
            try context.save()
        } catch {
            completion(.failure(.internalError(message: "Failed to save context", error: error)))
            return
        }
        
        // MARK: 5. Send
        apiService.transferFunds(sender: loggedAccount.address, recipient: recipient, amount: amount, keypair: keypair) { result in
            switch result {
            case .success(let id):
                // Update ID with recieved, add to unconfirmed transactions.
                transaction.transactionId = String(id)
                
                self.unconfirmedTransactions[id] = transaction.objectID
                
                do {
                    try context.save()
                } catch {
                    completion(.failure(.internalError(message: "Failed to save data context", error: error)))
                    break
                }
                
                if let trs = self.stack.container.viewContext.object(with: transaction.objectID) as? TransactionDetails {
                    completion(.success(transaction: trs))
                } else {
                    completion(.failure(.internalError(message: "Failed to get transaction in viewContext", error: nil)))
                }
                
            case .failure(let error):
                completion(.failure(.serverError(error)))
            }
        }
    }
    
    // MARK: Getting & refreshing transfers
    
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID
    /// - Returns: Transaction, if found
    func getTransfer(id: String) -> TransferTransaction? {
        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        
        do {
            let result = try stack.container.viewContext.fetch(request)
            return result.first
        } catch {
            return nil
        }
    }
    
    /// Search transaction in local storage
    ///
    /// - Parameter id: Transacton ID, context: NSManagedObjectContext
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
    /// Call Server, check if transaction updated
    ///
    /// - Parameters:
    ///   - id: Transaction ID
    ///   - completion: callback
    func refreshTransfer(id: String, completion: @escaping (TransfersProviderResult) -> Void) {
        guard let transfer = getTransfer(id: id) else {
            completion(.failure(.transactionNotFound(id: id)))
            return
        }
        
        guard let intId = UInt64(id) else {
            completion(.failure(.internalError(message: "Can't parse transaction id: \(id)", error: nil)))
            return
        }
        
        apiService.getTransaction(id: intId) { result in
            switch result {
            case .success(let transaction):
                guard transfer.confirmations != transaction.confirmations else {
                    completion(.success)
                    return
                }
                
                // Update transaction
                
                let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                context.parent = self.stack.container.viewContext
                
                guard let trsfr = context.object(with: transfer.objectID) as? TransferTransaction else {
                    completion(.failure(.internalError(message: "Failed to update transaction: CoreData context changed", error: nil)))
                    return
                }
                
                trsfr.confirmations = transaction.confirmations
                trsfr.blockId = transaction.blockId
                trsfr.isConfirmed = transaction.confirmations > 0 ? true : false
                
                do {
                    try context.save()
                    completion(.success)
                } catch {
                    completion(.failure(.internalError(message: "Failed saving changes to CoreData: \(error.localizedDescription)", error: error)))
                }
                
            case .failure(let error):
                completion(.failure(.serverError(error)))
            }
        }
    }
}

// MARK: - Data processing
extension AdamantTransfersProvider {
    private enum ProcessingResult {
        case success(new: Int)
        case accountNotFound(address: String)
        case error(Error)
    }
    
    /// Get transactions
    ///
    /// - Parameters:
    ///   - account: for account
    ///   - height: last transaction height.
    ///   - offset: offset, if greater than 100
    /// - Returns: ammount of new transactions was added
    private func getTransactions(forAccount account: String,
                                 type: TransactionType,
                                 fromHeight: Int64?,
                                 offset: Int?,
                                 dispatchGroup: DispatchGroup,
                                 context: NSManagedObjectContext,
                                 contextMutatingSemaphore cms: DispatchSemaphore) {
        // Enter 1
        dispatchGroup.enter()
        
        // MARK: 1. Get new transactions
        apiService.getTransactions(forAccount: account, type: type, fromHeight: fromHeight, offset: offset, limit: self.apiTransactions) { result in
            
            defer {
                // Leave 1
                dispatchGroup.leave()
            }
            
            switch result {
            case .success(let transactions):
                guard transactions.count > 0 else {
                    return
                }
                
                // MARK: 2. Process transactions in background
                // Enter 2
                dispatchGroup.enter()
                    defer {
                        // Leave 2
                        dispatchGroup.leave()
                    }
                    
                    self.processRawTransactions(transactions,
                                                currentAddress: account,
                                                context: context,
                                                contextMutatingSemaphore: cms)
                
                // MARK: 3. Get more transactions
                if transactions.count == self.apiTransactions {
                    let newOffset: Int
                    if let offset = offset {
                        newOffset = offset + self.apiTransactions
                    } else {
                        newOffset = self.apiTransactions
                    }
                    
                    self.getTransactions(forAccount: account, type: type, fromHeight: fromHeight, offset: newOffset, dispatchGroup: dispatchGroup, context: context, contextMutatingSemaphore: cms)
                }
                
            case .failure(let error):
                self.setState(.failedToUpdate(error), previous: .updating)
            }
        }
    }
    
    private func processRawTransactions(_ transactions: [Transaction],
                                        currentAddress address: String,
                                        context: NSManagedObjectContext,
                                        contextMutatingSemaphore cms: DispatchSemaphore) {
        let blockOperation = BlockOperation { [weak self] in
            self?.processRawTransactionsSynced(transactions, currentAddress: address, context: context, contextMutatingSemaphore: cms)
        }
        transactionService.addOperations(blockOperation)
    }
    
    private func processRawTransactionsSynced(_ transactions: [Transaction],
                                        currentAddress address: String,
                                        context: NSManagedObjectContext,
                                        contextMutatingSemaphore cms: DispatchSemaphore) {
        // MARK: 0. Transactions?
        guard transactions.count > 0 else {
            return
        }
        
        hasTransactions = true
        
        // MARK: 1. Collect all partners
        var partnerIds: Set<String> = []
        var partnerPublicKey: [String: String] = [:]
        
        for t in transactions {
            if t.senderId == address {
                partnerIds.insert(t.recipientId)
                partnerPublicKey[t.recipientId] = t.recipientPublicKey ?? ""
            } else {
                partnerIds.insert(t.senderId)
                partnerPublicKey[t.senderId] = t.senderPublicKey
            }
        }
        
        // MARK: 2. Let AccountProvider get all partners from server.
        let partnersGroup = DispatchGroup()
        var errors: [ProcessingResult] = []
        
        var ignorList: Set<String> = []
        
        for id in partnerIds {
            partnersGroup.enter() // Enter 1
            let publicKey = partnerPublicKey[id] ?? ""
            accountsProvider.getAccount(byAddress: id, publicKey: publicKey) { result in
                switch result {
                case .success, .dummy:
                    partnersGroup.leave() // Leave 1
                    
                case .notFound, .invalidAddress, .notInitiated:
                    self.accountsProvider.getDummyAccount(for: id) { result in
                        defer {
                            partnersGroup.leave() // Leave 1
                        }
                        
                        switch result {
                        case .success, .foundRealAccount:
                            break
                        
                        case .invalidAddress(let address):
                            ignorList.insert(address)
                        
                        case .internalError(let error):
                            errors.append(ProcessingResult.error(error))
                        }
                    }
                    
                case .networkError(let error), .serverError(let error):
                    errors.append(ProcessingResult.error(error))
                    partnersGroup.leave() // Leave 1
                }
            }
        }
        
        partnersGroup.wait()
        
        // MARK: 2.5. If we have any errors - drop processing.
        if let error = errors.first {
            print(error)
            return
        }
        
        ignorList.forEach { address in
            partnerIds.remove(address)
        }
        
        // MARK: 3. Create private context, and process transactions
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.stack.container.viewContext
        
        var partners: [String:BaseAccount] = [:]
        for id in partnerIds {
            let request = NSFetchRequest<BaseAccount>(entityName: BaseAccount.baseEntityName)
            request.predicate = NSPredicate(format: "address == %@", id)
            request.fetchLimit = 1
            if let partner = (try? context.fetch(request))?.first {
                partners[id] = partner
            }
        }
        
        var transfers = [TransferTransaction]()
        var height: Int64 = 0
        var transactionInProgress: [UInt64] = []
        
        for t in transactions {
            
            if ignorList.contains(t.senderId) || ignorList.contains(t.recipientId) {
                continue
            }
            
            transactionInProgress.append(t.id)
            if let objectId = unconfirmedTransactions[t.id], let transaction = context.object(with: objectId) as? TransferTransaction {
                transaction.isConfirmed = true
                transaction.height = t.height
                transaction.blockId = t.blockId
                transaction.confirmations = t.confirmations
                transaction.statusEnum = .delivered
                transaction.fee = t.fee as NSDecimalNumber
                
                unconfirmedTransactions.removeValue(forKey: t.id)
                
                let h = Int64(t.height)
                if height < h {
                    height = h
                }
                
                continue
            }
            
            let partner = partners[String(t.id)]
            let isOut = t.senderId == address
            
            let transfer = transactionService.transferTransaction(from: t, isOut: isOut, partner: partner, context: context)
           
            transfer.isOutgoing = t.senderId == address
            let partnerId = transfer.isOutgoing ? t.recipientId : t.senderId
            
            if let partner = partners[partnerId] {
                transfer.partner = partner
            }
            
            if t.height > height {
                height = t.height
            }
            
            transfers.append(transfer)
        }
        
        // MARK: 4. Check lastHeight
        // API returns transactions from lastHeight INCLUDING transaction with height == lastHeight, so +1
        
        if height > 0 {
            let uH = Int64(height + 1)
            
            if let lastHeight = receivedLastHeight {
                if lastHeight < uH {
                    self.receivedLastHeight = uH
                }
            } else {
                self.receivedLastHeight = uH
            }
        }
        // MARK: 5. Unread transactions
        if let unreadedHeight = readedLastHeight {
            let unreadTransactions = transfers.filter { !$0.isOutgoing && $0.height > unreadedHeight }
            
            if unreadTransactions.count > 0 {
                unreadTransactions.forEach { $0.isUnread = true }
                Set(unreadTransactions.compactMap { $0.chatroom }).forEach { $0.hasUnreadMessages = true }
            }
        }
                
        // MARK: 6. Dump transactions to viewContext
        if context.hasChanges {
            do {
                try context.save()

                // MARK: 7. Update lastTransactions
                let viewContextChatrooms = Set<Chatroom>(transfers.compactMap { $0.chatroom }).compactMap { self.stack.container.viewContext.object(with: $0.objectID) as? Chatroom }
                DispatchQueue.main.async {
                    viewContextChatrooms.forEach { $0.updateLastTransaction() }
                }
            } catch {
                print("TransferProvider: Failed to save changes to CoreData: \(error.localizedDescription)")
            }
        }
    }
    
}
