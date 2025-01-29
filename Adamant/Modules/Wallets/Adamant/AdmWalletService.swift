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
@preconcurrency import CoreData
import MessageKit
import Combine
import CommonKit

final class AdmWalletService: NSObject, WalletCoreProtocol, @unchecked Sendable {
    // MARK: - Constants
    let addressRegex = try! NSRegularExpression(pattern: "^U([0-9]{6,20})$")
    
    static let currencyLogo = UIImage.asset(named: "adamant_wallet") ?? .init()
    static var correctedDate: Date {
        Date() - 0.5
    }

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
    
    var nodeGroups: [NodeGroup] {
        [.adm]
    }
    
    var explorerAddress: String {
        Self.explorerAddress
    }
    
	// MARK: - Dependencies
	weak var accountService: AccountService?
	var apiService: AdamantApiServiceProtocol!
	var transfersProvider: TransfersProvider!
    var coreDataStack: CoreDataStack!
    var vibroService: VibroService!
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.admWallet.updated")
    let serviceEnabledChanged = Notification.Name("adamant.admWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.admWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.admWallet.stateChanged")
    
    @MainActor
    private let walletUpdateSender = ObservableSender<Void>()
    @MainActor
    var walletUpdatePublisher: AnyObservable<Void> {
        walletUpdateSender.eraseToAnyPublisher()
    }
    
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
    
    @MainActor
    var hasEnabledNode: Bool {
        apiService.hasEnabledNode
    }
    
    @MainActor
    var hasEnabledNodePublisher: AnyObservable<Bool> {
        apiService.hasEnabledNodePublisher
    }
    
    private(set) lazy var coinStorage: CoinStorageService = AdamantCoinStorageService(
        coinId: tokenUnicID,
        coreDataStack: coreDataStack,
        blockchainType: richMessageType
    )
    
    // MARK: - State
    @Atomic private(set) var state: WalletServiceState = .upToDate
    @Atomic private(set) var admWallet: AdmWallet?
    
    var wallet: WalletAccount? { admWallet }
    
    // MARK: - Logic
    override init() {
        super.init()
        
        // Notifications
        addObservers()
    }
    
    func addObservers() {
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.accountDataUpdated, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.admWallet = nil
            }
            .store(in: &subscriptions)
    }
    
    func update() {
        guard let accountService = accountService, let account = accountService.account else {
            admWallet = nil
            return
        }
        
        let isRaised: Bool
        
        if let wallet = admWallet {
            isRaised = (wallet.balance < account.balance) && wallet.isBalanceInitialized
            wallet.balance = account.balance
        } else {
            let wallet = AdmWallet(unicId: tokenUnicID, address: account.address)
            wallet.balance = account.balance
            
            admWallet = wallet
            isRaised = false
        }
        
        admWallet?.isBalanceInitialized = !accountService.isBalanceExpired
        
        if isRaised {
            Task { @MainActor in vibroService.applyVibration(.success) }
        }
        
        if let wallet = wallet {
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
        NotificationCenter.default.post(
            name: walletUpdatedNotification,
            object: self,
            userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
        )
        DispatchQueue.onMainThreadSyncSafe {
            walletUpdateSender.send()
        }
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        return address
    }
    
    func loadTransactions(offset: Int, limit: Int) async throws -> Int { .zero }
    
    func getTransactionsHistory(offset: Int, limit: Int) async throws -> [TransactionDetails] { [] }
    
    func getLocalTransactionHistory() -> [TransactionDetails] { [] }
    
    func updateStatus(for id: String, status: TransactionStatus?) { }
    
    func statusInfoFor(transaction: CoinTransaction) async -> TransactionStatusInfo {
        .init(sentDate: nil, status: .notInitiated)
    }
    
    func initWallet(withPassphrase: String, withPassword: String) async throws -> WalletAccount {
        throw InternalAPIError.unknownError
    }
    
    func setInitiationFailed(reason: String) { }
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
        apiService = container.resolve(AdamantApiServiceProtocol.self)
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
