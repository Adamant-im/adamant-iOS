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

class AdmWalletService: NSObject, WalletService {
    
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
    
    var tokenNetworkSymbol: String {
        return Self.currencySymbol
    }
    
    var tokenContract: String {
        return ""
    }
    
    var tokenUnicID: String {
        return tokenNetworkSymbol + tokenSymbol
    }
    
    var richMessageType: String {
        return Self.richMessageType
	}

    var qqPrefix: String {
        return Self.qqPrefix
    }
    
	// MARK: - Dependencies
	weak var accountService: AccountService?
	var apiService: ApiService!
	var transfersProvider: TransfersProvider!
    var router: Router!
    var coreDataStack: CoreDataStack!
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.admWallet.updated")
    let serviceEnabledChanged = Notification.Name("adamant.admWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.admWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.admWallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "adm_transaction" // not used
    
    // MARK: - Properties
    let enabled: Bool = true
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Adamant.wallet) as? AdmWalletViewController else {
            fatalError("Can't get AdmWalletViewController")
        }
        
        vc.service = self
        return vc
    }
    
    private var transfersController: NSFetchedResultsController<TransferTransaction>?
    private (set) var isWarningGasPrice = false
    private var subscriptions = Set<AnyCancellable>()

    @Published private(set) var transactions: [CoinTransaction] = []
    @Published private(set) var hasMoreOldTransactions: Bool = true

    var transactionsPublisher: Published<[CoinTransaction]>.Publisher {
        $transactions
    }
    
    var hasMoreOldTransactionsPublisher: Published<Bool>.Publisher {
        $hasMoreOldTransactions
    }
    
    lazy var coinStorage = AdamantCoinStorageService(
        coinId: tokenUnicID,
        coreDataStack: coreDataStack
    )
    
    // MARK: - State
    private (set) var state: WalletServiceState = .upToDate
    private (set) var wallet: WalletAccount?
    
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
    
    func addTransactionObserver() {
        coinStorage.$transactions
            .removeDuplicates()
            .sink { [weak self] transactions in
                self?.transactions = transactions
            }
            .store(in: &subscriptions)
    }
    
    func update() {
        guard let accountService = accountService, let account = accountService.account else {
            wallet = nil
            return
        }
                
        let notify: Bool
        if let wallet = wallet as? AdmWallet {
            wallet.isBalanceInitialized = true
            if wallet.balance != account.balance {
                wallet.balance = account.balance
                notify = true
            } else {
                notify = false
            }
        } else {
            let wallet = AdmWallet(address: account.address)
            wallet.isBalanceInitialized = true
            wallet.balance = account.balance
            
            self.wallet = wallet
            notify = true
        }
        
        if notify, let wallet = wallet {
            postUpdateNotification(with: wallet)
        }
    }
    
    // MARK: - Tools
    func getBalance(address: String) async throws -> Decimal {
        let account = try await apiService.getAccount(byAddress: address)
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
    
    func loadTransactions(offset: Int, limit: Int) async throws {
    }
}

extension AdmWalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        return router.get(scene: AdamantScene.Wallets.Adamant.transactionsList)
    }
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
        router = container.resolve(Router.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
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
