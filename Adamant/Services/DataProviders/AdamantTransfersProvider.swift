//
//  AdamantTransfersProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
@preconcurrency import CoreData
import Combine
import CommonKit

actor AdamantTransfersProvider: TransfersProvider {
    // MARK: Constants
    static let transferFee: Decimal = Decimal(sign: .plus, exponent: -1, significand: 5)
    
    // MARK: Dependencies
    let apiService: AdamantApiServiceProtocol
    private let stack: CoreDataStack
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    private let accountsProvider: AccountsProvider
    let securedStore: SecuredStore
    private let transactionService: ChatTransactionService
    weak var chatsProvider: ChatsProvider?
    
    @ObservableValue private(set) var state: State = .empty
    var stateObserver: AnyObservable<State> { $state.eraseToAnyPublisher() }
    private(set) var isInitiallySynced: Bool = false
    private(set) var receivedLastHeight: Int64?
    private(set) var readedLastHeight: Int64?
    private(set) var hasTransactions: Bool = false
    private let apiTransactions = 100
    
    private var unconfirmedTransactions: [UInt64:NSManagedObjectID] = [:]
    private var subscriptions = Set<AnyCancellable>()
    
    var offsetTransactions = 0
    
    // MARK: Tools
    
    /// Free stateSemaphore before calling this method, or you will deadlock.
    private func setState(_ state: State, previous prevState: State, notify: Bool = false) {
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
        apiService: AdamantApiServiceProtocol,
        stack: CoreDataStack,
        adamantCore: AdamantCore,
        accountService: AccountService,
        accountsProvider: AccountsProvider,
        securedStore: SecuredStore,
        transactionService: ChatTransactionService,
        chatsProvider: ChatsProvider
    ) {
        self.apiService = apiService
        self.stack = stack
        self.adamantCore = adamantCore
        self.accountService = accountService
        self.accountsProvider = accountsProvider
        self.securedStore = securedStore
        self.transactionService = transactionService
        self.chatsProvider = chatsProvider
        
        Task {
            await addObservers()
        }
    }
    
    private func addObservers() {
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn, object: nil)
            .sink { [weak self] notification in
                let loggedAddress = notification
                    .userInfo?[AdamantUserInfoKey.AccountService.loggedAccountAddress]
                    as? String
                
                await self?.userLoggedInAction(loggedAddress)
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut, object: nil)
            .sink { [weak self] _ in
                await self?.userLogOutAction()
            }
            .store(in: &subscriptions)
    }
    
    // MARK: - Notifications action
    
    private func userLoggedInAction(_ loggedAddress: String?) async {
        let store = securedStore
        
        guard let loggedAddress = loggedAddress else {
            store.remove(StoreKey.transfersProvider.address)
            store.remove(StoreKey.transfersProvider.receivedLastHeight)
            store.remove(StoreKey.transfersProvider.readedLastHeight)
            dropStateData()
            return
        }
        
        if let savedAddress: String = store.get(StoreKey.transfersProvider.address), savedAddress == loggedAddress {
            if let raw: String = store.get(StoreKey.transfersProvider.readedLastHeight), let h = Int64(raw) {
                readedLastHeight = h
            }
        } else {
            store.remove(StoreKey.transfersProvider.receivedLastHeight)
            store.remove(StoreKey.transfersProvider.readedLastHeight)
            dropStateData()
            store.set(loggedAddress, for: StoreKey.transfersProvider.address)
        }
        
        await loadFirstTransactions()
    }
    
    private func loadFirstTransactions() async {
        guard let loggedAddress = accountService.account?.address else { return }
        
        do {
            setState(.updating, previous: .empty, notify: false)
            
            _ = try await getTransactions(
                forAccount: loggedAddress,
                type: .send,
                offset: offsetTransactions,
                limit: apiTransactions,
                orderByTime: true
            )
            
            offsetTransactions += apiTransactions

            if !isInitiallySynced {
                isInitiallySynced = true
                NotificationCenter.default.post(name: Notification.Name.AdamantTransfersProvider.initialSyncFinished, object: self)
            }
            
            setState(.upToDate, previous: .updating, notify: false)
        } catch {
            setState(.failedToUpdate(error), previous: .updating, notify: false)
        }
    }
    
    private func userLogOutAction() {
        // Drop everything
        reset()
        
        // BackgroundFetch
        dropStateData()
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
    func reload() async {
        reset(notify: false)
        _ = await update()
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
        
        let prevHeight = receivedLastHeight
        
        await getTransactions(
            forAccount: address,
            type: .send,
            fromHeight: prevHeight,
            offset: nil,
            waitsForConnectivity: true
        )
        
        // MARK: 4. Check
        
        switch state {
        case .empty, .updating, .upToDate:
            setState(.upToDate, previous: prevState)
            
            if prevHeight != receivedLastHeight,
               let h = receivedLastHeight {
                NotificationCenter.default.post(
                    name: Notification.Name.AdamantChatsProvider.newUnreadMessages,
                    object: self,
                    userInfo: [AdamantUserInfoKey.TransfersProvider.lastTransactionHeight:h]
                )
            }
            
            if let h = receivedLastHeight {
                readedLastHeight = h
            } else {
                readedLastHeight = nil
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
                    
                case .serverError, .commonError, .noEndpointsAvailable:
                    err = .serverError(error)
                    
                case .internalError(let message, _):
                    err = .dependencyError(message: message)
                    
                case .networkError:
                    err = .networkError
                    
                case .requestCancelled:
                    err = .requestCancelled
                }
                
            default:
                err = TransfersProviderError.internalError(message: String.adamant.sharedErrors.internalError(message: error.localizedDescription), error: error)
            }
            
            return .failure(err)
        }
    }
    
    func reset() {
        reset(notify: true)
    }
    
    private func reset(notify: Bool) {
        offsetTransactions = 0
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
    func transferFunds(
        toAddress recipient: String,
        amount: Decimal,
        comment: String?,
        replyToMessageId: String?
    ) async throws -> AdamantTransactionDetails {
        let comment = comment ?? ""
        if !comment.isEmpty || replyToMessageId != nil {
            return try await transferFundsInternal(
                toAddress: recipient,
                amount: amount,
                comment: comment,
                replyToMessageId: replyToMessageId
            )
        }
        
        return try await transferFundsInternal(
            toAddress: recipient,
            amount: amount
        )
    }
    
    private func transferFundsInternal(
        toAddress recipient: String,
        amount: Decimal,
        comment: String,
        replyToMessageId: String?
    ) async throws -> AdamantTransactionDetails {
        // MARK: 0. Prepare
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            throw TransfersProviderError.notLogged
        }
        
        guard loggedAccount.balance > amount + Self.transferFee else {
            throw TransfersProviderError.notEnoughMoney
        }
        
        // MARK: 1. Get recipient

        let recipientAccount: CoreDataAccount
        
        do {
            recipientAccount = try await accountsProvider.getAccount(byAddress: recipient)
        } catch let error as AccountsProviderError {
            switch error {
            case .notFound, .invalidAddress, .notInitiated, .dummy:
                throw TransfersProviderError.accountNotFound(address: recipient)
                
            case .serverError(let error):
                throw TransfersProviderError.serverError(error)
                
            case .networkError:
                throw TransfersProviderError.networkError
            }
        }
        
        guard let recipientPublicKey = recipientAccount.publicKey else {
            throw TransfersProviderError.accountNotFound(address: recipient)
        }
        
        // MARK: 2. Chatroom
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        guard let id = recipientAccount.chatroom?.objectID,
              let chatroom = context.object(with: id) as? Chatroom,
              let partner = context.object(with: recipientAccount.objectID) as? BaseAccount
        else {
            throw TransfersProviderError.accountNotFound(address: recipient)
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
        transaction.transactionId = UUID().uuidString
        transaction.replyToId = replyToMessageId
        
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
            throw TransfersProviderError.internalError(message: String.adamant.sharedErrors.unknownError, error: error)
        }
        
        // MARK: 6. Encode
        
        let asset = replyToMessageId == nil
        ? comment
        : RichMessageReply(
            replyto_id: replyToMessageId ?? "",
            reply_message: comment
        ).serialized()
        
        guard let encodedMessage = adamantCore.encodeMessage(
            asset,
            recipientPublicKey: recipientPublicKey,
            privateKey: keypair.privateKey)
        else {
            throw TransfersProviderError.internalError(message: "Failed to encode message", error: nil)
        }
        
        // MARK: 7. Send
        
        let type: ChatType = replyToMessageId == nil
        ? .message
        : .richMessage
        
        let signedTransaction = try? adamantCore.makeSendMessageTransaction(
            senderId: loggedAccount.address,
            recipientId: recipient,
            keypair: keypair,
            message: encodedMessage.message,
            type: type,
            nonce: encodedMessage.nonce,
            amount: amount,
            date: AdmWalletService.correctedDate
        )
        
        guard let signedTransaction = signedTransaction else {
            throw TransfersProviderError.internalError(
                message: InternalAPIError.signTransactionFailed.localizedDescription,
                error: nil
            )
        }
        
        do {
            let id = try await apiService.sendMessageTransaction(transaction: signedTransaction).get()
            transaction.transactionId = String(id)
            await chatsProvider?.addUnconfirmed(transactionId: id, managedObjectId: transaction.objectID)
            
            do {
                try context.save()
            } catch {
                throw TransfersProviderError.internalError(
                    message: String.adamant.sharedErrors.unknownError,
                    error: error
                )
            }
            
            if let trs = stack.container.viewContext.object(with: transaction.objectID) as? TransferTransaction {
                return trs
            } else {
                throw TransfersProviderError.internalError(
                    message: "Failed to get transaction in viewContext",
                    error: nil
                )
            }
        } catch {
            transaction.statusEnum = MessageStatus.failed
            try? context.save()
            
            throw TransfersProviderError.serverError(error)
        }
    }
    
    private func transferFundsInternal(
        toAddress recipient: String,
        amount: Decimal
    ) async throws -> AdamantTransactionDetails {
        // MARK: 0. Prepare
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            throw TransfersProviderError.notLogged
        }
        
        guard loggedAccount.balance > amount + Self.transferFee else {
            throw TransfersProviderError.notEnoughMoney
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        // MARK: 1. Get recipient
        
        var recipientAccount: BaseAccount?
        
        do {
            recipientAccount = try await accountsProvider.getAccount(byAddress: recipient)
        } catch let error as AccountsProviderError {
            switch error {
            case .dummy(let account):
                recipientAccount = account
                
            case .notFound, .notInitiated:
                
                do {
                    recipientAccount = try await accountsProvider.getDummyAccount(for: recipient)
                } catch let error as AccountsProviderDummyAccountError {
                    switch error {
                    case .foundRealAccount(let account):
                        recipientAccount = account
                        
                    case .invalidAddress(let address):
                        throw TransfersProviderError.accountNotFound(address: address)
                        
                    case .internalError(let error):
                        throw TransfersProviderError.internalError(
                            message: error.localizedDescription,
                            error: error
                        )
                    }
                }
                
            case .invalidAddress:
                throw TransfersProviderError.accountNotFound(address: recipient)
                
            case .serverError(let error):
                throw TransfersProviderError.serverError(error)
                
            case .networkError:
                throw TransfersProviderError.networkError
            }
        } catch {
            throw error
        }
        
        let backgroundAccount: BaseAccount
        if let acc = recipientAccount,
            let obj = context.object(with: acc.objectID) as? BaseAccount {
            backgroundAccount = obj
        } else {
            throw TransfersProviderError.accountNotFound(address: recipient)
        }
        
        // MARK: 2. Create transaction
        let signedTransaction = adamantCore.createTransferTransaction(
            senderId: loggedAccount.address,
            recipientId: recipient,
            keypair: keypair,
            amount: amount,
            date: AdmWalletService.correctedDate
        )
        
        guard let signedTransaction = signedTransaction else {
            throw TransfersProviderError.internalError(
                message: InternalAPIError.signTransactionFailed.localizedDescription,
                error: InternalAPIError.signTransactionFailed
            )
        }
        
        let locallyID = signedTransaction.generateId() ?? UUID().uuidString
        let transaction = TransferTransaction(context: context)
        transaction.amount = amount as NSDecimalNumber
        transaction.date = Date() as NSDate
        transaction.recipientId = recipient
        transaction.senderId = loggedAccount.address
        transaction.type = Int16(TransactionType.send.rawValue)
        transaction.isOutgoing = true
        transaction.showsChatroom = false
        transaction.fee = Self.transferFee as NSDecimalNumber
        
        transaction.transactionId = locallyID
        transaction.blockId = nil
        transaction.chatMessageId = locallyID
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
            throw TransfersProviderError.internalError(
                message: "Failed to save context",
                error: error
            )
        }
        
        // MARK: 5. Send
        do {
            let id = try await apiService.transferFunds(
                transaction: signedTransaction
            ).get()
            
            transaction.transactionId = String(id)
            
            self.unconfirmedTransactions[id] = transaction.objectID
            
            do {
                try context.save()
            } catch {
                throw TransfersProviderError.internalError(
                    message: "Failed to save data context",
                    error: error
                )
            }
            
            if let trs = self.stack.container.viewContext.object(with: transaction.objectID) as? AdamantTransactionDetails {
                return trs
            } else {
                throw TransfersProviderError.internalError(
                    message: "Failed to get transaction in viewContext",
                    error: nil
                )
            }
        } catch {
            throw TransfersProviderError.serverError(error)
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
    func refreshTransfer(id: String) async throws {
        guard let transfer = getTransfer(id: id) else {
            throw TransfersProviderError.transactionNotFound(id: id)
        }
        
        guard let intId = UInt64(id) else {
            throw TransfersProviderError.internalError(
                message: "Can't parse transaction id: \(id)",
                error: nil
            )
        }
        
        do {
            let transaction = try await apiService.getTransaction(id: intId).get()
            
            guard transfer.confirmations != transaction.confirmations else {
                return
            }
            
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            context.parent = self.stack.container.viewContext
            
            guard let trsfr = context.object(with: transfer.objectID) as? TransferTransaction else {
                throw TransfersProviderError.internalError(
                    message: "Failed to update transaction: CoreData context changed",
                    error: nil
                )
            }
            
            trsfr.confirmations = transaction.confirmations
            trsfr.blockId = transaction.blockId
            trsfr.isConfirmed = transaction.confirmations > 0 ? true : false
            
            do {
                try context.save()
                return
            } catch {
                throw TransfersProviderError.internalError(
                    message: "Failed saving changes to CoreData: \(error.localizedDescription)",
                    error: error
                )
            }
        } catch {
            throw TransfersProviderError.serverError(error)
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
    private func getTransactions(
        forAccount account: String,
        type: TransactionType,
        fromHeight: Int64?,
        offset: Int?,
        waitsForConnectivity: Bool
    ) async {
        
        do {
            let transactions = try await apiService.getTransactions(
                forAccount: account,
                type: type,
                fromHeight: fromHeight,
                offset: offset,
                limit: self.apiTransactions,
                waitsForConnectivity: waitsForConnectivity
            ).get()
            
            guard transactions.count > 0 else {
                return
            }
            
            // MARK: 2. Process transactions in background
    
            await processRawTransactions(
                transactions,
                currentAddress: account
            )
            
            // MARK: 3. Get more transactions
            if transactions.count == self.apiTransactions {
                let newOffset: Int
                if let offset = offset {
                    newOffset = offset + self.apiTransactions
                } else {
                    newOffset = self.apiTransactions
                }
                
                await self.getTransactions(
                    forAccount: account,
                    type: type,
                    fromHeight: fromHeight,
                    offset: newOffset,
                    waitsForConnectivity: waitsForConnectivity
                )
            }
        } catch {
            setState(.failedToUpdate(error), previous: .updating)
        }
    }
    
    func getTransactions(
        forAccount account: String,
        type: TransactionType,
        offset: Int,
        limit: Int,
        orderByTime: Bool
    ) async throws -> Int {
        let transactions = try await apiService.getTransactions(
            forAccount: account,
            type: type,
            fromHeight: nil,
            offset: offset,
            limit: limit,
            orderByTime: orderByTime,
            waitsForConnectivity: true
        ).get()
        
        guard transactions.count > 0 else {
            return 0
        }
        
        // MARK: 2. Process transactions in background
        
        await processRawTransactions(
            transactions,
            currentAddress: account
        )
        
        return transactions.count
    }
    
    func updateOffsetTransactions(_ value: Int) {
        offsetTransactions = value
    }
    
    private func processRawTransactions(
        _ transactions: [Transaction],
        currentAddress address: String
    ) async {
        
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
        var errors: [ProcessingResult] = []
        
        var ignorList: Set<String> = []
        
        for id in partnerIds {
            let publicKey = partnerPublicKey[id] ?? ""
            
            do {
                _ = try await accountsProvider.getAccount(
                    byAddress: id,
                    publicKey: publicKey
                )
            } catch let error as AccountsProviderError {
                switch error {
                case .dummy:
                    break
                    
                case .notFound, .invalidAddress, .notInitiated:
                    do {
                        _ = try await accountsProvider.getDummyAccount(for: id)
                    } catch let error as AccountsProviderDummyAccountError {
                        switch error {
                        case .foundRealAccount:
                            break
                            
                        case .invalidAddress(let address):
                            ignorList.insert(address)
                            
                        case .internalError(let error):
                            errors.append(ProcessingResult.error(error))
                        }
                    } catch {
                        ignorList.insert(id)
                    }
                    
                case .networkError(let error), .serverError(let error):
                    errors.append(ProcessingResult.error(error))
                }
            } catch {
                ignorList.insert(id)
            }
        }
        
        // MARK: 2.5. If we have any errors - drop processing.
        if let error = errors.first {
            print(error)
            return
        }
        
        ignorList.forEach { address in
            partnerIds.remove(address)
        }
        
        // MARK: 3. Create private context, and process transactions
        let contextPrivate = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        contextPrivate.parent = self.stack.container.viewContext
        contextPrivate.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
        
        var partners: [String:BaseAccount] = [:]
        for id in partnerIds {
            let request = NSFetchRequest<BaseAccount>(entityName: BaseAccount.baseEntityName)
            request.predicate = NSPredicate(format: "address == %@", id)
            request.fetchLimit = 1
            if let partner = (try? contextPrivate.fetch(request))?.first {
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
            if let objectId = unconfirmedTransactions[t.id],
               let transaction = contextPrivate.object(with: objectId) as? TransferTransaction {
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
            
            let isOutgoing = t.senderId == address
            let partnerId = isOutgoing ? t.recipientId : t.senderId
            let partner = partners[partnerId]
            
            let transfer = await transactionService.transferTransaction(
                from: t,
                isOut: isOutgoing,
                partner: partner,
                context: contextPrivate
            )
           
            transfer.isOutgoing = isOutgoing
            
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
        do {
            let rooms = transfers.compactMap { $0.chatroom }
            
            if contextPrivate.hasChanges {
                try contextPrivate.save()
                await updateContext(rooms: rooms)
            }
        } catch {
            print(error)
        }
    }
    
    @MainActor func updateContext(rooms: [Chatroom]) async {
        let viewContextChatrooms = Set<Chatroom>(rooms).compactMap {
            self.stack.container.viewContext.object(with: $0.objectID) as? Chatroom
        }
        
        for chatroom in viewContextChatrooms {
            chatroom.updateLastTransaction()
        }
    }
}
