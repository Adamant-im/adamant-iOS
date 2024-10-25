//
//  DashWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Swinject
import Alamofire
import BitcoinKit
import Combine
import CommonKit

struct DashApiComand {
    static let networkInfoMethod: String = "getnetworkinfo"
    static let blockchainInfoMethod: String = "getblockchaininfo"
    static let rawTransactionMethod: String = "getrawtransaction"
}

final class DashWalletService: WalletCoreProtocol, @unchecked Sendable {
    
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
    
    static var tokenNetworkSymbol: String {
        return "DASH"
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
        [.dash]
    }
    
    var wallet: WalletAccount? { return dashWallet }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "dash_transaction"
    
    // MARK: - Dependencies
    var apiService: AdamantApiServiceProtocol!
    var dashApiService: DashApiService!
    var accountService: AccountService!
    var securedStore: SecuredStore!
    var dialogService: DialogService!
    var addressConverter: AddressConverter!
    var coreDataStack: CoreDataStack!
    var vibroService: VibroService!
    
    // MARK: - Constants
    static let currencyLogo = UIImage.asset(named: "dash_wallet") ?? .init()
    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)
    static let chunkSize = 20
    
    var transactionFee: Decimal {
        return DashWalletService.fixedFee
    }
    
    @Atomic private(set) var isWarningGasPrice = false
    
    static let kvsAddress = "dash:address"
    
    @Atomic var transatrionsIds = [String]()
    
    var lastTransactionId: String? {
        get {
            guard
                let hash: String = self.securedStore.get("lastDashTransactionId"),
                let timestampString: String = self.securedStore.get("lastDashTransactionTime"),
                let timestamp = Double(string: timestampString)
            else { return nil }
            
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let timeAgo = -1 * date.timeIntervalSinceNow
            
            if timeAgo > 10 * 60 { // 10m waiting for transaction complete
                self.securedStore.remove("lastDashTransactionTime")
                self.securedStore.remove("lastDashTransactionId")
                return nil
            } else {
                return hash
            }
        }
        set {
            if let value = newValue {
                let timestamp = Date().timeIntervalSince1970
                self.securedStore.set("\(timestamp)", for: "lastDashTransactionTime")
                self.securedStore.set(value, for: "lastDashTransactionId")
            } else {
                self.securedStore.remove("lastDashTransactionTime")
                self.securedStore.remove("lastDashTransactionId")
            }
        }
    }
    
    @MainActor
    var hasEnabledNode: Bool {
        dashApiService.hasEnabledNode
    }
    
    @MainActor
    var hasEnabledNodePublisher: AnyObservable<Bool> {
        dashApiService.hasEnabledNodePublisher
    }
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.dashWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.dashWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.dashWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.dashWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    @Atomic private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Properties
    @Atomic private(set) var dashWallet: DashWallet?
    @Atomic private(set) var enabled = true
    @Atomic public var network: Network
    @Atomic private var cachedWalletAddress: [String: String] = [:]
    @Atomic private var balanceInvalidationSubscription: AnyCancellable?
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.dashWalletService", qos: .userInteractive, attributes: [.concurrent])
    
    static let jsonDecoder = JSONDecoder()
    @Atomic private var subscriptions = Set<AnyCancellable>()

    @ObservableValue private(set) var historyTransactions: [TransactionDetails] = []
    @ObservableValue private(set) var hasMoreOldTransactions: Bool = true

    var transactionsPublisher: AnyObservable<[TransactionDetails]> {
        $historyTransactions.eraseToAnyPublisher()
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
    @Atomic private(set) var state: WalletServiceState = .notInitiated
    
    private func setState(_ newState: WalletServiceState, silent: Bool = false) {
        guard newState != state else {
            return
        }
        
        state = newState
        
        if !silent {
            NotificationCenter.default.post(
                name: serviceStateChanged,
                object: self,
                userInfo: [AdamantUserInfoKey.WalletService.walletState: state]
            )
        }
    }
    
    init() {
        self.network = DashMainnet()
        
        self.setState(.notInitiated)
        
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
                self?.dashWallet = nil
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
                self?.coinStorage.clear()
                self?.hasMoreOldTransactions = true
                self?.historyTransactions = []
                self?.balanceInvalidationSubscription = nil
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: UIApplication.didBecomeActiveNotification, object: nil)
            .sink { [weak self] _ in self?.setBalanceInvalidationSubscription() }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: UIApplication.willResignActiveNotification, object: nil)
            .sink { [weak self] _ in self?.balanceInvalidationSubscription = nil }
            .store(in: &subscriptions)
    }
    
    func addTransactionObserver() {
        coinStorage.transactionsPublisher
            .sink { [weak self] transactions in
                self?.historyTransactions = transactions
            }
            .store(in: &subscriptions)
    }
    
    func update() {
        Task {
            await update()
        }
    }
    
    func update() async {
        guard let wallet = dashWallet else {
            return
        }
        
        switch state {
        case .notInitiated, .updating, .initiationFailed:
            return
            
        case .upToDate:
            break
        }
        
        setState(.updating)
        
        if let balance = try? await getBalance() {
            setBalanceInvalidationSubscription()
            let notification: Notification.Name?
            let isRaised = (wallet.balance < balance) && wallet.isBalanceInitialized
            
            if wallet.balance != balance {
                wallet.balance = balance
                notification = walletUpdatedNotification
            } else if !wallet.isBalanceInitialized {
                notification = walletUpdatedNotification
            } else {
                notification = nil
            }
            
            wallet.isBalanceInitialized = true
            
            if isRaised {
                await vibroService.applyVibration(.success)
            }
            
            if let notification = notification {
                NotificationCenter.default.post(
                    name: notification,
                    object: self,
                    userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
                )
            }
        }
        
        setState(.upToDate)
    }
    
    func validate(address: String) -> AddressValidationResult {
        let address = try? addressConverter.convert(address: address)
        
        switch address?.scriptType {
        case .p2pk, .p2pkh, .p2sh:
            return .valid
        case .p2tr, .p2multi, .p2wpkh, .p2wpkhSh, .p2wsh, .unknown, .none:
            return .invalid(description: nil)
        }
    }
    
    private func setBalanceInvalidationSubscription() {
        balanceInvalidationSubscription = Task { [weak self] in
            await Task.sleep(interval: Self.balanceLifetime)
            try Task.checkCancellation()
            self?.resetBalance()
        }.eraseToAnyCancellable()
    }
    
    private func resetBalance() {
        dashWallet?.isBalanceInitialized = false
        guard let wallet = dashWallet else { return }
        
        NotificationCenter.default.post(
            name: walletUpdatedNotification,
            object: self,
            userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
        )
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension DashWalletService {
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        dashWallet = nil
    }
    
    @MainActor
    func initWallet(withPassphrase passphrase: String) async throws -> WalletAccount {
        guard let adamant = accountService.account else {
            throw WalletServiceError.notLogged
        }
        
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        let privateKeyData = passphrase.data(using: .utf8)!.sha256()
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        let eWallet = try DashWallet(
            unicId: tokenUnicID,
            privateKey: privateKey,
            addressConverter: addressConverter
        )
        
        self.dashWallet = eWallet
        
        NotificationCenter.default.post(
            name: walletUpdatedNotification,
            object: self,
            userInfo: [AdamantUserInfoKey.WalletService.wallet: eWallet]
        )
        
        if !self.enabled {
            self.enabled = true
            NotificationCenter.default.post(name: self.serviceEnabledChanged, object: self)
        }
        
        // MARK: 4. Save address into KVS
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            let service = self
            if address != eWallet.address {
                service.save(dashAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(dashAddress: eWallet.address, result: result)
                }
            }
            
            service.setState(.upToDate)
            
            Task {
                service.update()
            }
            return eWallet
        } catch let error as WalletServiceError {
            let service = self
            switch error {
            case .walletNotInitiated:
                /// The ADM Wallet is not initialized. Check the balance of the current wallet
                /// and save the wallet address to kvs when dropshipping ADM
                service.setState(.upToDate)
                
                Task {
                    await service.update()
                }
                
                service.save(dashAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(dashAddress: eWallet.address, result: result)
                }
                service.setState(.upToDate)
                return eWallet
                
            default:
                service.setState(.upToDate)
                throw error
            }
        }
    }
}

// MARK: - Dependencies
extension DashWalletService: SwinjectDependentService {
    @MainActor
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(AdamantApiServiceProtocol.self)
        securedStore = container.resolve(SecuredStore.self)
        dialogService = container.resolve(DialogService.self)
        addressConverter = container.resolve(AddressConverterFactory.self)?
            .make(network: network)
        dashApiService = container.resolve(DashApiService.self)
        vibroService = container.resolve(VibroService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
    }
}

// MARK: - Balances & addresses
extension DashWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = dashWallet?.address else {
            throw WalletServiceError.walletNotInitiated
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        let data: Data = try await dashApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequest(
                origin: origin,
                path: .empty,
                method: .post,
                parameters: DashGetAddressBalanceDTO(address: address),
                encoding: .json
            )
        }.get()
        
        let object = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: Any]

        guard let object = object else {
            throw WalletServiceError.remoteServiceError(
                message: "DASH Wallet: not valid response"
            )
        }
        
        let result = object["result"] as? [String: Any]
        let error = object["error"]
        
        if error is NSNull, let result = result, let raw = result["balance"] as? Int64 {
            let balance = Decimal(raw) / DashWalletService.multiplier
            return balance
        } else {
            throw WalletServiceError.remoteServiceError(message: "DASH Wallet: \(data)")
        }
    }

    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        do {
            let result = try await apiService.get(key: DashWalletService.kvsAddress, sender: address).get()
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            cachedWalletAddress[address] = result
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "DASH Wallet: failed to get address from KVS"
            )
        }
    }
    
    func loadTransactions(offset: Int, limit: Int) async throws -> Int {
        let trs = try await getTransactionsHistory(offset: offset, limit: limit)
        
        guard trs.count > 0 else {
            hasMoreOldTransactions = false
            return .zero
        }
        
        coinStorage.append(trs)
        
        return trs.count
    }
    
    func getTransactionsHistory(offset: Int, limit: Int) async throws -> [TransactionDetails] {
        guard let address = wallet?.address else {
            throw WalletServiceError.accountNotFound
        }
        
        let allTransactionsIds = try await requestTransactionsIds(for: address).reversed()
        
        let availableToLoad = allTransactionsIds.count - offset
        
        let maxPerRequest = availableToLoad > limit
        ? limit
        : availableToLoad
        
        let startIndex = allTransactionsIds.index(allTransactionsIds.startIndex, offsetBy: offset)
        let endIndex = allTransactionsIds.index(startIndex, offsetBy: maxPerRequest)
        let ids = Array(allTransactionsIds[startIndex..<endIndex])
        
        let trs = try await getTransactions(by: ids)
        
        return trs
    }
    
    func getLocalTransactionHistory() -> [TransactionDetails] {
        historyTransactions
    }
    
    func updateStatus(for id: String, status: TransactionStatus?) {
        coinStorage.updateStatus(for: id, status: status)
    }
}

// MARK: - KVS
extension DashWalletService {
    /// - Parameters:
    ///   - dashAddress: DASH address to save into KVS
    ///   - adamantAddress: Owner of Dash address
    ///   - completion: success
    private func save(dashAddress: String, completion: @escaping @Sendable (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(error: .notLogged))
            return
        }

        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughMoney))
            return
        }

        Task { @Sendable in
            let result = await apiService.store(
                key: DashWalletService.kvsAddress,
                value: dashAddress,
                type: .keyValue,
                sender: adamant.address,
                keypair: keypair
            )
            
            switch result {
            case .success:
                completion(.success)

            case .failure(let error):
                completion(.failure(error: .apiError(error)))
            }
        }
    }
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(dashAddress: String, result: WalletServiceSimpleResult) {
        if let observer = balanceObserver {
            NotificationCenter.default.removeObserver(observer)
            balanceObserver = nil
        }

        switch result {
        case .success:
            break

        case .failure(let error):
            switch error {
            case .notEnoughMoney:  // Possibly new account, we need to wait for dropship
                // Register observer
                let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
                    guard let balance = self?.accountService.account?.balance, balance > AdamantApiService.KvsFee else {
                        return
                    }

                    self?.save(dashAddress: dashAddress) { [weak self] result in
                        self?.kvsSaveCompletionRecursion(dashAddress: dashAddress, result: result)
                    }
                }

                // Save referense to unregister it later
                balanceObserver = observer

            default:
                print("\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - PrivateKey generator
extension DashWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Dash"
    }
    
    var rowImage: UIImage? {
        return .asset(named: "dash_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let privateKeyData = passphrase.data(using: .utf8)?.sha256() else {
            return nil
        }
        
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        return privateKey.toWIF()
    }
}
