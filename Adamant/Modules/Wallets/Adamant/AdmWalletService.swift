//
//  AdmWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import CoreData
import MessageKit
import Combine
import CommonKit

final class AdmWalletService: NSObject, WalletService {
    
    // MARK: - Constants
    let addressRegex = try! NSRegularExpression(pattern: "^U([0-9]{6,20})$")
    
    static let currencyLogo = UIImage.asset(named: "adamant_wallet") ?? .init()

    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
    
    var transactionFee: Decimal {
        return AdmWalletService.fixedFee
    }
    
    static var tokenNetworkSymbol: String {
        return Self.currencySymbol
    }
    
    var tokenContract: String {
        return ""
    }
    
    var tokenUnicID: String {
        Self.tokenNetworkSymbol + tokenSymbol
    }
    
    var richMessageType: String {
        return Self.richMessageType
	}

    var qqPrefix: String {
        return Self.qqPrefix
    }
    
    var transferDecimals: Int {
        Self.cryptoTransferDecimals
    }
    
	// MARK: - Dependencies
	weak var accountService: AccountService?
	var apiService: ApiService!
	var transfersProvider: TransfersProvider!
    var coreDataStack: CoreDataStack!
    var vibroService: VibroService!
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.admWallet.updated")
    let serviceEnabledChanged = Notification.Name("adamant.admWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.admWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.admWallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "adm_transaction" // not used
    
    // MARK: - Properties
    let enabled: Bool = true
    
    private var transfersController: NSFetchedResultsController<TransferTransaction>?
    @Atomic private(set) var isWarningGasPrice = false
    @Atomic private var subscriptions = Set<AnyCancellable>()

    @ObservableValue private(set) var transactions: [TransactionDetails] = []
    @ObservableValue private(set) var hasMoreOldTransactions: Bool = true

    var transactionsPublisher: AnyObservable<[TransactionDetails]> {
        $transactions.eraseToAnyPublisher()
    }
    
    var hasMoreOldTransactionsPublisher: AnyObservable<Bool> {
        $hasMoreOldTransactions.eraseToAnyPublisher()
    }
    
    private(set) lazy var coinStorage: CoinStorageService = AdamantCoinStorageService(
        coinId: tokenUnicID,
        coreDataStack: coreDataStack,
        blockchainType: richMessageType
    )
    
    // MARK: - State
    @Atomic private(set) var state: WalletServiceState = .upToDate
    @Atomic private(set) var wallet: WalletAccount?
    
    // MARK: - Logic
    override init() {
        super.init()
        
        // Notifications
        addObservers()
    }
    
    func addObservers() {
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.accountDataUpdated, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.wallet = nil
            }
            .store(in: &subscriptions)
    }
    
    func update() {
        guard let accountService = accountService, let account = accountService.account else {
            wallet = nil
            return
        }
                
        let notify: Bool
        
        let isRaised: Bool
        
        if let wallet = wallet as? AdmWallet {
            isRaised = (wallet.balance < account.balance) && wallet.isBalanceInitialized
            if wallet.balance != account.balance {
                wallet.balance = account.balance
                notify = true
            } else if wallet.isBalanceInitialized {
                notify = true
            } else {
                notify = false
            }
            wallet.isBalanceInitialized = true
        } else {
            let wallet = AdmWallet(address: account.address)
            wallet.isBalanceInitialized = true
            wallet.balance = account.balance
            
            self.wallet = wallet
            notify = true
            isRaised = false
        }
        
        if isRaised {
            vibroService.applyVibration(.success)
        }
        if notify, let wallet = wallet {
            postUpdateNotification(with: wallet)
        }
    }
    
    // MARK: - Tools
    func getBalance(address: String) async throws -> Decimal {
        let account = try await apiService.getAccount(byAddress: address).get()
        return account.balance
    }
    
    func validate(address: String) -> AddressValidationResult {
        addressRegex.perfectMatch(with: address) ? .valid : .invalid(description: nil)
    }
    
    private func postUpdateNotification(with wallet: WalletAccount) {
        NotificationCenter.default.post(name: walletUpdatedNotification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        return address
    }
    
    func loadTransactions(offset: Int, limit: Int) async throws -> Int { .zero }
    
    func getLocalTransactionHistory() -> [TransactionDetails] { [] }
    
    func updateStatus(for id: String, status: TransactionStatus?) { }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AdmWalletService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let newCount = controller.fetchedObjects?.count, let wallet = wallet as? AdmWallet else {
            return
        }
        
        if newCount != wallet.notifications {
            wallet.notifications = newCount
            postUpdateNotification(with: wallet)
        }
    }
}

// MARK: - Dependencies
extension AdmWalletService: SwinjectDependentService {
    @MainActor
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        transfersProvider = container.resolve(TransfersProvider.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        vibroService = container.resolve(VibroService.self)
        
        Task {
            let controller = await transfersProvider.unreadTransfersController()
            
            do {
                try controller.performFetch()
            } catch {
                print("AdmWalletService: Error performing fetch: \(error)")
            }
            
            controller.delegate = self
            transfersController = controller
        }
    }
}
