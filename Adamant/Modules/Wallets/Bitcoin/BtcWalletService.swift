//
//  BtcWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Swinject
import Alamofire
import BitcoinKit
import Combine
import CommonKit

enum DefaultBtcTransferFee: Decimal {
    case high = 24000
    case medium = 12000
    case low = 3000
}

struct BtcApiCommands {

    static let blockchainInfoMethod: String = "getblockchaininfo"
    static let networkInfoMethod: String = "getnetworkinfo"
    
    static func getRPC() -> String {
        return "/bitcoind"
    }
    
    static func getHeight() -> String {
        return "/blocks/tip/height"
    }

    static func getFeeRate() -> String {
        return "/fee-estimates" //this._get('').then(estimates => estimates['2'])
    }

    static func balance(for address: String) -> String {
        return "/address/\(address)"
    }

    static func getTransactions(for address: String, fromTx: String? = nil) -> String {
        var url = "/address/\(address)/txs"
        if let fromTx = fromTx {
            url += "/chain/\(fromTx)"
        }
        return url
    }

    static func getTransaction(by hash: String) -> String {
        return "/tx/\(hash)"
    }
    
    static func getUnspentTransactions(for address: String) -> String {
        return "/address/\(address)/utxo"
    }
    
    static func sendTransaction() -> String {
        return "/tx"
    }
}

// MARK: - Localization
extension String.adamant {
    enum BtcWalletService {
        static var taprootNotSupported: String {
            String.localized("WalletServices.SharedErrors.BtcTaproot", comment: "")
        }
    }
}

final class BtcWalletService: WalletCoreProtocol {

    var tokenSymbol: String {
        type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        type(of: self).currencyLogo
    }
    
    static var tokenNetworkSymbol: String {
        "BTC"
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

    var isSupportIncreaseFee: Bool {
        return true
    }
    
    var isIncreaseFeeEnabled: Bool {
        return increaseFeeService.isIncreaseFeeEnabled(for: tokenUnicID)
    }
    
    var wallet: WalletAccount? { return btcWallet }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "btc_transaction"
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var btcApiService: BtcApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var increaseFeeService: IncreaseFeeService!
    var addressConverter: AddressConverter!
    var coreDataStack: CoreDataStack!
    var vibroService: VibroService!
    
    // MARK: - Constants
    static let currencyLogo = UIImage.asset(named: "bitcoin_wallet") ?? .init()
    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)

    @Atomic private(set) var currentHeight: Decimal?
    @Atomic private var feeRate: Decimal = 1
    @Atomic private(set) var transactionFee: Decimal = DefaultBtcTransferFee.medium.rawValue / multiplier
    @Atomic private(set) var isWarningGasPrice = false
    @Atomic private var cachedWalletAddress: [String: String] = [:]
    
    static let kvsAddress = "btc:address"
    private let walletPath = "m/44'/0'/21'/0/0"
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.brchWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.btcWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.btcWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.btcWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    @Atomic private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Properties
    @Atomic private(set) var btcWallet: BtcWallet?
    @Atomic private(set) var enabled = true
    @Atomic public var network: Network
    
    static let jsonDecoder = JSONDecoder()
    
    let defaultDispatchQueue = DispatchQueue(
        label: "im.adamant.btcWalletService",
        qos: .userInteractive,
        attributes: [.concurrent]
    )
    
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
    @Atomic private(set) var state: WalletServiceState = .notInitiated
    
    private func setState(_ newState: WalletServiceState, silent: Bool = false) {
        guard newState != state else {
            return
        }
        
        state = newState
        
        if !silent {
            NotificationCenter.default.post(name: serviceStateChanged,
                                            object: self,
                                            userInfo: [AdamantUserInfoKey.WalletService.walletState: state])
        }
    }
    
    init() {
        self.network = BTCMainnet()
        self.setState(.notInitiated)
        
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
                self?.btcWallet = nil
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
                self?.coinStorage.clear()
                self?.hasMoreOldTransactions = true
                self?.transactions = []
            }
            .store(in: &subscriptions)
    }
    
    func addTransactionObserver() {
        coinStorage.transactionsPublisher
            .sink { [weak self] transactions in
                self?.transactions = transactions
            }
            .store(in: &subscriptions)
    }
    
    func update() {
        Task {
            await update()
        }
    }
    
    func update() async {
        guard let wallet = btcWallet else {
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
                vibroService.applyVibration(.success)
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
        
        if let rate = try? await getFeeRate() {
            feeRate = rate
        }
        
        if let height = try? await getCurrentHeight() {
            currentHeight = height
        }
        
        if let transactions = try? await getUnspentTransactions() {
            let feeRate = feeRate
            
            let fee = Decimal(transactions.count * 181 + 78) * feeRate
            var newTransactionFee = fee / BtcWalletService.multiplier
            
            newTransactionFee = isIncreaseFeeEnabled
            ? newTransactionFee * defaultIncreaseFee
            : newTransactionFee
            
            guard transactionFee != newTransactionFee else { return }
            
            transactionFee = newTransactionFee
            
            NotificationCenter.default.post(name: transactionFeeUpdated, object: self, userInfo: nil)
        }
    }
    
    func validate(address: String) -> AddressValidationResult {
        let address = try? addressConverter.convert(address: address)
        
        switch address?.scriptType {
        case .p2pk, .p2pkh, .p2sh, .p2multi, .p2wpkh, .p2wpkhSh, .p2wsh:
            return .valid
        case .p2tr:
            return .invalid(description: .adamant.BtcWalletService.taprootNotSupported)
        case .unknown, .none:
            return .invalid(description: nil)
        }
    }

    private func getBase58DecodeAsBytes(address: String, length: Int) -> [UTF8.CodeUnit]? {
        let b58Chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

        var output: [UTF8.CodeUnit] = Array(repeating: 0, count: length)

        for i in 0..<address.count {
            let index = address.index(address.startIndex, offsetBy: i)
            let charAtIndex = address[index]

            guard let charLoc = b58Chars.firstIndex(of: charAtIndex) else { continue }

            var p = b58Chars.distance(from: b58Chars.startIndex, to: charLoc)
            for j in stride(from: length - 1, through: 0, by: -1) {
                p += 58 * Int(output[j] & 0xFF)
                output[j] = UTF8.CodeUnit(p % 256)

                p /= 256
            }

            guard p == 0 else { return nil }
        }

        return output
    }

    public func isValid(bitcoinAddress address: String) -> Bool {
        (try? addressConverter.convert(address: address)) != nil
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        do {
            let result = try await apiService.get(key: BtcWalletService.kvsAddress, sender: address).get()
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            cachedWalletAddress[address] = result
            
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "BTC Wallet: failed to get address from KVS"
            )
        }
    }

    private func isValid(bech32 address: String) -> Bool {
        guard let decoded = try? SegwitAddrCoder().decode(hrp: "bc", addr: address) else {
            return false
        }

        do {
            let recoded = try SegwitAddrCoder().encode(
                hrp: "bc",
                version: decoded.version,
                program: decoded.program
            )
            return !recoded.isEmpty
        } catch {
            return false
        }
    }

}

// MARK: - WalletInitiatedWithPassphrase
extension BtcWalletService {
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        btcWallet = nil
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
        let eWallet = try BtcWallet(privateKey: privateKey, addressConverter: addressConverter)
        self.btcWallet = eWallet
        
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
                service.save(btcAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(btcAddress: eWallet.address, result: result)
                }
                throw WalletServiceError.accountNotFound
            }
            
            service.setState(.upToDate, silent: true)
            Task {
                service.update()
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
                
                service.save(btcAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(btcAddress: eWallet.address, result: result)
                }
                
                return eWallet
                
            default:
                service.setState(.upToDate)
                throw error
            }
        }
        
    }

}

// MARK: - Dependencies
extension BtcWalletService: SwinjectDependentService {
    @MainActor
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        increaseFeeService = container.resolve(IncreaseFeeService.self)
        addressConverter = container.resolve(AddressConverterFactory.self)?.make(network: network)
        btcApiService = container.resolve(BtcApiService.self)
        vibroService = container.resolve(VibroService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
    }
}

// MARK: - Balances & addresses
extension BtcWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = btcWallet?.address else {
            throw WalletServiceError.walletNotInitiated
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        let response: BtcBalanceResponse = try await btcApiService.request { api, node in
            await api.sendRequestJsonResponse(node: node, path: BtcApiCommands.balance(for: address))
        }.get()

        return response.value / BtcWalletService.multiplier
    }

    func getFeeRate() async throws -> Decimal {
        let response: [String: Decimal] = try await btcApiService.request { api, node in
            await api.sendRequestJsonResponse(node: node, path: BtcApiCommands.getFeeRate())
        }.get()
        
        return response["2"] ?? 1
    }

    func getCurrentHeight() async throws -> Decimal {
        try await .init(btcApiService.getStatusInfo().get().height)
    }

}

// MARK: - KVS
extension BtcWalletService {
    /// - Parameters:
    ///   - btcAddress: Bitcoin address to save into KVS
    ///   - adamantAddress: Owner of BTC address
    ///   - completion: success
    private func save(btcAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(error: .notLogged))
            return
        }
        
        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughMoney))
            return
        }
        
        Task {
            let result = await apiService.store(
                key: BtcWalletService.kvsAddress,
                value: btcAddress,
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
    private func kvsSaveCompletionRecursion(btcAddress: String, result: WalletServiceSimpleResult) {
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
                    
                    self?.save(btcAddress: btcAddress) { result in
                        self?.kvsSaveCompletionRecursion(btcAddress: btcAddress, result: result)
                    }
                }
                
                // Save referense to unregister it later
                balanceObserver = observer
                
            default:
                Task { @MainActor in dialogService.showRichError(error: error) }
            }
        }
    }
    
    private func kvsSaveCompletionRecursion(btcCheckpoint: Checkpoint, result: WalletServiceSimpleResult) {
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
                }
                
                // Save referense to unregister it later
                balanceObserver = observer
                
            default:
                Task { @MainActor in dialogService.showRichError(error: error) }
            }
        }
    }
}

// MARK: - Transactions
extension BtcWalletService {
    func getTransactions(fromTx: String? = nil) async throws -> [BtcTransaction] {
        guard let address = self.wallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        let items = try await getTransactions(
            for: address,
            fromTx: fromTx
        )
        let transactions = items.map {
            $0.asBtcTransaction(
                BtcTransaction.self,
                for: address,
                height: self.currentHeight
            )
        }
        
        return transactions
    }

    private func getTransactions(
        for address: String,
        fromTx: String? = nil
    ) async throws -> [RawBtcTransactionResponse] {
        return try await btcApiService.request { api, node in
            await api.sendRequestJsonResponse(
                node: node,
                path: BtcApiCommands.getTransactions(
                    for: address,
                    fromTx: fromTx
                )
            )
        }.get()
    }

    func getTransaction(by hash: String) async throws -> BtcTransaction {
        guard let address = self.wallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        let rawTransaction: RawBtcTransactionResponse = try await btcApiService.request { api, node in
            await api.sendRequestJsonResponse(
                node: node,
                path: BtcApiCommands.getTransaction(by: hash)
            )
        }.get()
        
        return rawTransaction.asBtcTransaction(
            BtcTransaction.self,
            for: address,
            height: self.currentHeight
        )
    }

    func loadTransactions(offset: Int, limit: Int) async throws -> Int {
        let txId = offset == .zero
        ? transactions.first?.txId
        : transactions.last?.txId
        
        let trs = try await getTransactions(fromTx: txId)
        
        guard trs.count > 0 else {
            hasMoreOldTransactions = false
            return .zero
        }
        
        coinStorage.append(trs)
    
        return trs.count
    }
    
    func getLocalTransactionHistory() -> [TransactionDetails] {
        transactions
    }
    
    func updateStatus(for id: String, status: TransactionStatus?) {
        coinStorage.updateStatus(for: id, status: status)
    }
}

// MARK: - PrivateKey generator
extension BtcWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Bitcoin"
    }
    
    var rowImage: UIImage? {
        return .asset(named: "bitcoin_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard
            AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase),
            let privateKeyData = passphrase.data(using: .utf8)?.sha256()
        else {
            return nil
        }

        let privateKey = PrivateKey(data: privateKeyData,
                                    network: self.network,
                                    isPublicKeyCompressed: true)
        return privateKey.toWIF()
    }
}

final class BtcTransaction: BaseBtcTransaction {
    override var defaultCurrencySymbol: String? { BtcWalletService.currencySymbol }
}
