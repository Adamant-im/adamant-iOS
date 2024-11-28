//
//  DogeWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Swinject
import Alamofire
import BitcoinKit
import Combine
import CommonKit

struct DogeApiCommands {
    static func balance(for address: String) -> String {
        return "/api/addr/\(address)/balance"
    }
    
    static func getTransactions(for address: String) -> String {
        return "/api/addrs/\(address)/txs"
    }
    
    static func getTransaction(by hash: String) -> String {
        return "/api/tx/\(hash)"
    }
    
    static func getBlock(by hash: String) -> String {
        return "/api/block/\(hash)"
    }
    
    static func getBlocks() -> String {
        return "/api/blocks"
    }
    
    static func getUnspentTransactions(for address: String) -> String {
        return "/api/addr/\(address)/utxo"
    }
    
    static func sendTransaction() -> String {
        return "/api/tx/send"
    }
    
    static func getInfo() -> String {
        return "/api/status"
    }
}

final class DogeWalletService: WalletCoreProtocol, @unchecked Sendable {
    var wallet: WalletAccount? { return dogeWallet }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "doge_transaction"
    
    // MARK: - Dependencies
    var apiService: AdamantApiServiceProtocol!
    var dogeApiService: DogeApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var addressConverter: AddressConverter!
    var vibroService: VibroService!
    var coreDataStack: CoreDataStack!
    var chatsProvider: ChatsProvider!
    
    // MARK: - Constants
    static let currencyLogo = UIImage.asset(named: "doge_wallet") ?? .init()
    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)
    static let chunkSize = 20
 
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
    
    static var tokenNetworkSymbol: String {
        return "DOGE"
    }
   
    var tokenContract: String {
        return ""
    }
    
    var tokenUnicID: String {
        Self.tokenNetworkSymbol + tokenSymbol
    }
    
    var transactionFee: Decimal {
        return DogeWalletService.fixedFee
    }
    
    var richMessageType: String {
        return Self.richMessageType
	}
    
    var explorerAddress: String {
        Self.explorerAddress
    }
    
    var qqPrefix: String {
        return Self.qqPrefix
    }
    
    var nodeGroups: [NodeGroup] {
        [.doge]
    }
    
    static let kvsAddress = "doge:address"
    
    @Atomic private(set) var isWarningGasPrice = false
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.dogeWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.dogeWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.dogeWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.dogeWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    @Atomic private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Properties
    @Atomic private(set) var dogeWallet: DogeWallet?
    @Atomic private(set) var enabled = true
    @Atomic public var network: Network
    @Atomic private var cachedWalletAddress: [String: String] = [:]
    @Atomic private var balanceInvalidationSubscription: AnyCancellable?
    
    let defaultDispatchQueue = DispatchQueue(
        label: "im.adamant.dogeWalletService",
        qos: .userInteractive,
        attributes: [.concurrent]
    )
    
    private static let jsonDecoder = JSONDecoder()
    @Atomic private var subscriptions = Set<AnyCancellable>()

    @ObservableValue private(set) var historyTransactions: [TransactionDetails] = []
    @ObservableValue private(set) var hasMoreOldTransactions: Bool = true

    var transactionsPublisher: AnyObservable<[TransactionDetails]> {
        $historyTransactions.eraseToAnyPublisher()
    }
    
    var hasMoreOldTransactionsPublisher: AnyObservable<Bool> {
        $hasMoreOldTransactions.eraseToAnyPublisher()
    }
    
    @MainActor
    var hasEnabledNode: Bool {
        dogeApiService.hasEnabledNode
    }
    
    @MainActor
    var hasEnabledNodePublisher: AnyObservable<Bool> {
        dogeApiService.hasEnabledNodePublisher
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
        self.network = DogeMainnet()
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
                self?.dogeWallet = nil
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
        guard let wallet = dogeWallet else {
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
                NotificationCenter.default.post(name: notification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
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
            try await Task.sleep(interval: Self.balanceLifetime, pauseInBackground: true)
            self?.resetBalance()
        }.eraseToAnyCancellable()
    }
    
    private func resetBalance() {
        dogeWallet?.isBalanceInitialized = false
        guard let wallet = dogeWallet else { return }
        
        NotificationCenter.default.post(
            name: walletUpdatedNotification,
            object: self,
            userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
        )
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension DogeWalletService {
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        dogeWallet = nil
    }
    
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
        
        let eWallet = try DogeWallet(
            unicId: tokenUnicID,
            privateKey: privateKey,
            addressConverter: addressConverter
        )
        self.dogeWallet = eWallet
        
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
        let service = self
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            if address != eWallet.address {
                service.save(dogeAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
                }
            }
            
            service.setState(.upToDate)
            
            Task {
                await service.update()
            }
            
            return eWallet
        } catch let error as WalletServiceError {
            switch error {
            case .walletNotInitiated:
                /// The ADM Wallet is not initialized. Check the balance of the current wallet
                /// and save the wallet address to kvs when dropshipping ADM
                service.setState(.upToDate)
                
                Task {
                    await service.update()
                }
                
                service.save(dogeAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
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
extension DogeWalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(AdamantApiServiceProtocol.self)
        dialogService = container.resolve(DialogService.self)
        addressConverter = container.resolve(AddressConverterFactory.self)?
            .make(network: network)
        dogeApiService = container.resolve(DogeApiService.self)
        vibroService = container.resolve(VibroService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        chatsProvider = container.resolve(ChatsProvider.self)
        
        addTransactionObserver()
    }
}

// MARK: - Balances & addresses
extension DogeWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = dogeWallet?.address else {
            throw WalletServiceError.walletNotInitiated
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        let data: Data = try await dogeApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequest(
                origin: origin,
                path: DogeApiCommands.balance(for: address)
            )
        }.get()
        
        if
            let string = String(data: data, encoding: .utf8),
            let raw = Decimal(string: string)
        {
            let balance = raw / DogeWalletService.multiplier
            return balance
        } else {
            throw WalletServiceError.internalError(InternalAPIError.parsingFailed)
        }
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        do {
            let result = try await apiService.get(key: DogeWalletService.kvsAddress, sender: address).get()
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            cachedWalletAddress[address] = result
            
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "DOGE Wallet: failed to get address from KVS"
            )
        }
    }
}

// MARK: - KVS
extension DogeWalletService {
    /// - Parameters:
    ///   - dogeAddress: DOGE address to save into KVS
    ///   - adamantAddress: Owner of Doge address
    ///   - completion: success
    private func save(dogeAddress: String, completion: @escaping @Sendable (WalletServiceSimpleResult) -> Void) {
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
                key: DogeWalletService.kvsAddress,
                value: dogeAddress,
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
    private func kvsSaveCompletionRecursion(dogeAddress: String, result: WalletServiceSimpleResult) {
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
                    
                    self?.save(dogeAddress: dogeAddress) { [weak self] result in
                        self?.kvsSaveCompletionRecursion(dogeAddress: dogeAddress, result: result)
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

// MARK: - Transactions
extension DogeWalletService {
    func getTransactions(from: Int) async throws -> (transactions: [DogeTransaction], hasMore: Bool) {
        guard let address = self.wallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        let doge = try await getTransactions(
            for: address,
            from: from,
            to: from + DogeWalletService.chunkSize
        )
        
        let hasMore = doge.to < doge.totalItems
        
        let transactions = doge.items.filter { !$0.isDoubleSpend }.map { $0.asBtcTransaction(DogeTransaction.self, for: address) }
        
        return (transactions: transactions, hasMore: hasMore)
    }
    
    private func getTransactions(
        for address: String,
        from: Int,
        to: Int
    ) async throws -> DogeGetTransactionsResponse {
        let parameters = [
            "from": from,
            "to": to
        ]
        
        return try await dogeApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: DogeApiCommands.getTransactions(for: address),
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }.get()
    }
    
    func getUnspentTransactions() async throws -> [UnspentTransaction] {
        guard let wallet = self.dogeWallet else {
            throw WalletServiceError.notLogged
        }
        
        let address = wallet.address
        
        let parameters = [
            "noCache": "1"
        ]
        
        // MARK: Sending request
        let data = try await dogeApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequest(
                origin: origin,
                path: DogeApiCommands.getUnspentTransactions(for: address),
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }.get()
        
        let items = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [[String: Any]]
        
        guard let items = items else {
            throw WalletServiceError.remoteServiceError(
                message: "DOGE Wallet: not valid response"
            )
        }

        var utxos = [UnspentTransaction]()
        for item in items {
            guard
                let txid = item["txid"] as? String,
                let confirmations = item["confirmations"] as? NSNumber,
                confirmations.intValue > 0,
                let vout = item["vout"] as? NSNumber,
                let amount = item["amount"] as? NSNumber else {
                continue
            }

            let value = NSDecimalNumber(decimal: (amount.decimalValue * DogeWalletService.multiplier)).uint64Value
            
            let lockScript = wallet.addressEntity.lockingScript
            let txHash = Data(hex: txid).map { Data($0.reversed()) } ?? Data()
            let txIndex = vout.uint32Value

            let unspentOutput = TransactionOutput(value: value, lockingScript: lockScript)
            let unspentOutpoint = TransactionOutPoint(hash: txHash, index: txIndex)
            let utxo = UnspentTransaction(output: unspentOutput, outpoint: unspentOutpoint)

            utxos.append(utxo)
        }

        return utxos
    }
    
    func getTransaction(by hash: String, waitsForConnectivity: Bool) async throws -> BTCRawTransaction {
        try await dogeApiService.request(waitsForConnectivity: waitsForConnectivity) { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: DogeApiCommands.getTransaction(by: hash)
            )
        }.get()
    }
    
    func getBlockId(by hash: String) async throws -> String {
        let data = try await dogeApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequest(origin: origin, path: DogeApiCommands.getBlock(by: hash))
        }.get()
        
        let json = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: Any]
        
        guard let json = json else {
            throw WalletServiceError.remoteServiceError(
                message: "DOGE Wallet: not valid response"
            )
        }
        
        if let height = json["height"] as? NSNumber {
            return height.stringValue
        } else {
            throw WalletServiceError.remoteServiceError(message: "Failed to parse block")
        }
    }
    
    func loadTransactions(offset: Int, limit: Int) async throws -> Int {
        let tuple = try await getTransactions(from: offset)
        
        let trs = tuple.transactions
        hasMoreOldTransactions = tuple.hasMore
        
        guard trs.count > 0 else {
            hasMoreOldTransactions = false
            return .zero
        }
        
        coinStorage.append(trs)
        
        return trs.count
    }
    
    func getTransactionsHistory(offset: Int, limit: Int) async throws -> [TransactionDetails] {
        try await getTransactions(from: offset).transactions
    }
    
    func getLocalTransactionHistory() -> [TransactionDetails] {
        return historyTransactions
    }
    
    func updateStatus(for id: String, status: TransactionStatus?) {
        coinStorage.updateStatus(for: id, status: status)
    }
}

// MARK: - PrivateKey generator
extension DogeWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Doge"
    }
    
    var rowImage: UIImage? {
        return .asset(named: "doge_wallet_row")
    }
    
    var keyFormat: KeyFormat { .WIF }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let privateKeyData = passphrase.data(using: .utf8)?.sha256() else {
            return nil
        }
            
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        return privateKey.toWIF()
    }
}
