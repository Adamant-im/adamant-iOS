//
//  AdamantTransfersProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

class AdamantTransfersProvider: TransfersProvider {
	// MARK: Dependencies
	var apiService: ApiService!
	var stack: CoreDataStack!
	var accountService: AccountService!
	var accountsProvider: AccountsProvider!
	var securedStore: SecuredStore!
	
	// MARK: Properties
	var transferFee: Decimal = Decimal(sign: .plus, exponent: -1, significand: 5)
	
	private(set) var state: State = .empty
	private(set) var isInitiallySynced: Bool = false
	private(set) var receivedLastHeight: Int64?
	private(set) var readedLastHeight: Int64?
    private let apiTransactions = 100
	
	private let processingQueue = DispatchQueue(label: "im.Adamant.processing.transfers", qos: .utility, attributes: [.concurrent])
	private let stateSemaphore = DispatchSemaphore(value: 1)
	
	// MARK: Tools
	
	/// Free stateSemaphore before calling this method, or you will deadlock.
	private func setState(_ state: State, previous prevState: State, notify: Bool = true) {
		stateSemaphore.wait()
		self.state = state
		stateSemaphore.signal()
		
		if notify {
			switch prevState {
			case .failedToUpdate(_):
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
	init() {
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
			
			if let savedAddress = store.get(StoreKey.transfersProvider.address), savedAddress == loggedAddress {
				if let raw = store.get(StoreKey.transfersProvider.readedLastHeight), let h = Int64(raw) {
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
}


// MARK: - DataProvider
extension AdamantTransfersProvider {
	func reload() {
		reset(notify: false)
		
		update()
	}
	
	func update() {
		stateSemaphore.wait()
		if state == .updating {
			stateSemaphore.signal()
			return
		}
		
		let prevState = state
		state = .updating
		stateSemaphore.signal()
		
		guard let address = accountService.account?.address else {
			self.setState(.failedToUpdate(TransfersProviderError.notLogged), previous: prevState)
			return
		}
        
        // MARK: 3. Get transactions
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = self.stack.container.viewContext
        let processingGroup = DispatchGroup()
        let cms = DispatchSemaphore(value: 1)
        let prevHeight = receivedLastHeight
		
        getTransactions(forAccount: address, type: .send, fromHeight: prevHeight, offset: nil, dispatchGroup: processingGroup, context: privateContext, contextMutatingSemaphore: cms)
        
        // MARK: 4. Check
        processingGroup.notify(queue: DispatchQueue.global(qos: .utility)) { [weak self] in
            guard let state = self?.state else {
                return
            }
            
            switch state {
            case .failedToUpdate(_): // Processing failed
                break
                
            default:
                self?.setState(.upToDate, previous: prevState)
                
                if prevHeight != self?.receivedLastHeight, let h = self?.receivedLastHeight {
                    NotificationCenter.default.post(name: Notification.Name.AdamantChatsProvider.newUnreadMessages,
                                                    object: self,
                                                    userInfo: [AdamantUserInfoKey.TransfersProvider.lastTransactionHeight:h])
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
                    NotificationCenter.default.post(name: Notification.Name.AdamantTransfersProvider.initialSyncFinished, object: self)
                }
            }
        }
	}
	
	func reset() {
		reset(notify: true)
	}
	
	private func reset(notify: Bool) {
		isInitiallySynced = false
		let prevState = self.state
		setState(.updating, previous: prevState, notify: false)	// Block update calls
		
		// Drop props
		receivedLastHeight = nil
		readedLastHeight = nil
		
		// Drop store
		securedStore.remove(StoreKey.transfersProvider.address)
		securedStore.remove(StoreKey.transfersProvider.receivedLastHeight)
		securedStore.remove(StoreKey.transfersProvider.readedLastHeight)
		
		// Drop CoreData
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		context.parent = stack.container.viewContext
		
		if let result = try? context.fetch(request) {
			for obj in result {
				context.delete(obj)
			}
			
			try? context.save()
		}
		
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
	func transferFunds(toAddress recipient: String, amount: Decimal, completion: @escaping (TransfersProviderResult) -> Void) {
		guard let senderAddress = accountService.account?.address, let keypair = accountService.keypair else {
			completion(.error(.notLogged))
			return
		}
		
		apiService.transferFunds(sender: senderAddress, recipient: recipient, amount: amount, keypair: keypair) { result in
			switch result {
			case .success(_):
				completion(.success)
				
			case .failure(let error):
				completion(.error(.serverError(error)))
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
                self.processingQueue.async {
                    defer {
                        // Leave 2
                        dispatchGroup.leave()
                    }
                    
                    self.processRawTransactions(transactions,
                                                currentAddress: account,
                                                context: context,
                                                contextMutatingSemaphore: cms)
                }
                
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
    
    /// Get transaction
    ///
    /// - Parameters:
    ///   - id: transation ID
    /// - Returns: Transaction object
    func getTransaction(id: UInt64, completion: @escaping (TransferTransaction) -> Void) {
        apiService.getTransaction(id: id, completion: { (result) in
            switch result {
            case .success(let transaction):
                print("Updating transaction: Recive data")
                self.updateTransaction(id: id, with: transaction, completion: { (processedTransaction) in
                    completion(processedTransaction)
                })
            case .failure(let error):
                print("Updating transaction: Recive error")
                print(error)
            }
        })
    }
    
    private func updateTransaction(id: UInt64, with rawTransaction:Transaction, completion: @escaping (TransferTransaction) -> Void) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.stack.container.viewContext
        
        let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
        request.predicate = NSPredicate(format: "transactionId == %@", String(id))
        request.fetchLimit = 1
        if let transaction = (try? context.fetch(request))?.first {
            transaction.confirmations = rawTransaction.confirmations
            completion(transaction)
        }
        
        if context.hasChanges {
            do {
                try context.save()
                
                print(".success")
            } catch {
                print(error)
            }
        } else {
            print(".empty")
        }
    }
    
    private func processRawTransactions(_ transactions: [Transaction],
                                        currentAddress address: String,
                                        context: NSManagedObjectContext,
                                        contextMutatingSemaphore cms: DispatchSemaphore) {
        // MARK: 0. Transactions?
        guard transactions.count > 0 else {
            return
        }
        
        // MARK: 1. Collect all partners
        var partnerIds: Set<String> = []
        
        for t in transactions {
            if t.senderId == address {
                partnerIds.insert(t.recipientId)
            } else {
                partnerIds.insert(t.senderId)
            }
        }
        
        // MARK: 2. Let AccountProvider get all partners from server.
        let partnersGroup = DispatchGroup()
        var errors: [ProcessingResult] = []
        for id in partnerIds {
            partnersGroup.enter()
            accountsProvider.getAccount(byAddress: id, completion: { result in
                defer {
                    partnersGroup.leave()
                }
                
                switch result {
                case .success(_):
                    break
                    
                case .notFound, .invalidAddress:
					errors.append(ProcessingResult.accountNotFound(address: id))
                    
                case .serverError(let error):
                    errors.append(ProcessingResult.error(error))
                }
            })
        }
        
        partnersGroup.wait()
        
        // MARK: 2.5. If we have any errors - drop processing.
        if let error = errors.first {
            print(error)
            return
        }
        
        
        // MARK: 3. Create private context, and process transactions
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.stack.container.viewContext
        
        var partners: [String:CoreDataAccount] = [:]
        for id in partnerIds {
            let request = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
            request.predicate = NSPredicate(format: "address == %@", id)
            request.fetchLimit = 1
            if let partner = (try? context.fetch(request))?.first {
                partners[id] = partner
            }
        }
        
        var transfers = [TransferTransaction]()
        var height: Int64 = 0
        for t in transactions {
            let transfer = TransferTransaction(entity: TransferTransaction.entity(), insertInto: context)
            transfer.amount = t.amount as NSDecimalNumber
            transfer.date = t.date as NSDate
            transfer.fee = t.fee as NSDecimalNumber
            transfer.height = Int64(t.height)
            transfer.recipientId = t.recipientId
            transfer.senderId = t.senderId
            transfer.transactionId = String(t.id)
            transfer.type = Int16(t.type.rawValue)
            transfer.blockId = t.blockId
            transfer.confirmations = t.confirmations
            
            transfer.isOutgoing = t.senderId == address
            let partnerId = transfer.isOutgoing ? t.recipientId : t.senderId
            
            if let partner = partners[partnerId] {
                transfer.partner = partner
                transfer.chatroom = partner.chatroom
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
            let unreadTransactions = transfers.filter { $0.height > unreadedHeight }
            let chatrooms = Dictionary.init(grouping: unreadTransactions, by: ({ (t: TransferTransaction) -> Chatroom in t.chatroom!}))
            
            for (chatroom, trs) in chatrooms {
                chatroom.hasUnreadMessages = true
                trs.forEach { $0.isUnread = true }
            }
            
            transfers.filter({$0.height > unreadedHeight}).forEach({$0.isUnread = true})
            
            readedLastHeight = self.receivedLastHeight
        }
        
        if let h = self.receivedLastHeight {
            securedStore.set(String(h), for: StoreKey.transfersProvider.receivedLastHeight)
        }
        
        if let h = self.readedLastHeight {
            securedStore.set(String(h), for: StoreKey.transfersProvider.readedLastHeight)
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
                print(".success \(transfers.count)")
                //                completion(.success(new: transfers.count))
            } catch {
                //                completion(.error(error))
                print(error)
            }
        } else {
            //            completion(.success(new: 0))
            print(".success 0")
        }
    }
	
}
