//
//  ERC20WalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import web3swift
import Alamofire
@preconcurrency import struct BigInt.BigUInt
@preconcurrency import Web3Core
import Combine
import CommonKit

final class ERC20WalletService: WalletCoreProtocol, @unchecked Sendable {
    // MARK: - Constants
    let addressRegex = try! NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
    
    static let currencySymbol: String = ""
    static let currencyLogo: UIImage = UIImage()
    static let qqPrefix: String = ""
    
    var minBalance: Decimal = 0
    var minAmount: Decimal = 0
    
    var tokenSymbol: String {
        return token.symbol
    }
    
    var tokenName: String {
        return token.name
    }
    
    var tokenLogo: UIImage {
        return token.logo
    }
    
    static var tokenNetworkSymbol: String {
        return "ERC20"
    }
    
    var consistencyMaxTime: Double {
        return 1200
    }
    
    var tokenContract: String {
        return token.contractAddress
    }
   
    var tokenUnicID: String {
        Self.tokenNetworkSymbol + tokenSymbol + tokenContract
    }
    
    var defaultVisibility: Bool {
        return token.defaultVisibility
    }
    
    var defaultOrdinalLevel: Int? {
        return token.defaultOrdinalLevel
    }
    
    var richMessageType: String {
        return Self.richMessageType
	}

    var qqPrefix: String {
        return EthWalletService.qqPrefix
	}

    var isSupportIncreaseFee: Bool {
        return true
    }
    
    var isIncreaseFeeEnabled: Bool {
        return increaseFeeService.isIncreaseFeeEnabled(for: tokenUnicID)
    }
    
    var nodeGroups: [NodeGroup] {
        [.eth]
    }

    var transferDecimals: Int {
        token.transferDecimals
    }
    
    var explorerAddress: String {
        EthWalletService.explorerAddress
    }
    
    private(set) var blockchainSymbol: String = "ETH"
    private(set) var isDynamicFee: Bool = true
    private(set) var transactionFee: Decimal = 0.0
    private(set) var gasPrice: BigUInt = 0
    private(set) var gasLimit: BigUInt = 0
    private(set) var isWarningGasPrice = false
    
    var isTransactionFeeValid: Bool {
        return ethWallet?.balance ?? 0 > transactionFee
    }
    
    static let transferGas: Decimal = 21000
    static let kvsAddress = "eth:address"
    
    static let walletPath = "m/44'/60'/3'/1"
    static let walletPassword = ""
    
    // MARK: - Dependencies
    weak var accountService: AccountService?
    var apiService: AdamantApiServiceProtocol!
    var erc20ApiService: ERC20ApiService!
    var dialogService: DialogService!
    var increaseFeeService: IncreaseFeeService!
    var vibroService: VibroService!
    var coreDataStack: CoreDataStack!
    
    // MARK: - Notifications
    let walletUpdatedNotification: Notification.Name
    let serviceEnabledChanged: Notification.Name
    let transactionFeeUpdated: Notification.Name
    let serviceStateChanged: Notification.Name
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "erc20_transaction"
    var dynamicRichMessageType: String {
        return "\(self.token.symbol.lowercased())_transaction"
    }
    
    // MARK: - Properties
    
    let token: ERC20Token
    @Atomic private(set) var enabled = true
    @Atomic private var subscriptions = Set<AnyCancellable>()
    @Atomic private var cachedWalletAddress: [String: String] = [:]
    @Atomic private var balanceInvalidationSubscription: AnyCancellable?
    
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
    
    private(set) var ethWallet: EthWallet?
    var wallet: WalletAccount? { return ethWallet }
    private var balanceObserver: NSObjectProtocol?
    
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
        erc20ApiService.hasEnabledNode
    }
    
    @MainActor
    var hasEnabledNodePublisher: AnyObservable<Bool> {
        erc20ApiService.hasEnabledNodePublisher
    }
    
    private(set) lazy var coinStorage: CoinStorageService = AdamantCoinStorageService(
        coinId: tokenUnicID,
        coreDataStack: coreDataStack,
        blockchainType: dynamicRichMessageType
    )
    
    init(token: ERC20Token) {
        self.token = token
        walletUpdatedNotification = Notification.Name("adamant.erc20Wallet.\(token.symbol).walletUpdated")
        serviceEnabledChanged = Notification.Name("adamant.erc20Wallet.\(token.symbol).enabledChanged")
        transactionFeeUpdated = Notification.Name("adamant.erc20Wallet.\(token.symbol).feeUpdated")
        serviceStateChanged = Notification.Name("adamant.erc20Wallet.\(token.symbol).stateChanged")
        
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
                self?.ethWallet = nil
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
        guard let wallet = ethWallet else {
            return
        }
        
        switch state {
        case .notInitiated, .updating, .initiationFailed:
            return
            
        case .upToDate:
            break
        }
        
        setState(.updating)
        
        if let balance = try? await getBalance(forAddress: wallet.ethAddress) {
            markBalanceAsFresh()
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
            
            if isRaised {
                await vibroService.applyVibration(.success)
            }
            
            if let notification = notification {
                NotificationCenter.default.post(name: notification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
            }
        }
        
        setState(.upToDate)
        
        await calculateFee()
    }
    
    func calculateFee(for address: EthereumAddress? = nil) async {
        let priceRaw = try? await getGasPrices()
        let gasLimitRaw = try? await getGasLimit(to: address)
        
        var price = priceRaw ?? BigUInt(token.defaultGasPriceGwei).toWei()
        var gasLimit = gasLimitRaw ?? BigUInt(token.defaultGasLimit)
        
        let pricePercent = price * BigUInt(token.reliabilityGasPricePercent) / 100
        let gasLimitPercent = gasLimit * BigUInt(token.reliabilityGasLimitPercent) / 100
        
        price = priceRaw == nil
        ? price
        : price + pricePercent
        
        gasLimit = gasLimitRaw == nil
        ? gasLimit
        : gasLimit + gasLimitPercent

        var newFee = (price * gasLimit).asDecimal(exponent: EthWalletService.currencyExponent)

        newFee = isIncreaseFeeEnabled
        ? newFee * defaultIncreaseFee
        : newFee
        
        guard transactionFee != newFee else { return }
        
        transactionFee = newFee
        let incGasPrice = UInt64(price.asDouble() * defaultIncreaseFee.doubleValue)
                
        gasPrice = isIncreaseFeeEnabled
        ? BigUInt(integerLiteral: incGasPrice)
        : price
        
        isWarningGasPrice = gasPrice >= BigUInt(token.warningGasPriceGwei).toWei()
        self.gasLimit = gasLimit
        
        NotificationCenter.default.post(name: transactionFeeUpdated, object: self, userInfo: nil)
    }
    
    func validate(address: String) -> AddressValidationResult {
        return addressRegex.perfectMatch(with: address) ? .valid : .invalid(description: nil)
    }
    
    func getGasPrices() async throws -> BigUInt {
        try await erc20ApiService.requestWeb3(waitsForConnectivity: false) { web3 in
            try await web3.eth.gasPrice()
        }.get()
    }
    
    func getGasLimit(to address: EthereumAddress?) async throws -> BigUInt {
        guard let ethWallet = ethWallet else {
            throw WalletServiceError.internalError(message: "Can't get ethWallet service", error: nil)
        }
        
        let transaction = try await erc20ApiService.requestERC20(token: token) { erc20 in
            try await erc20.transfer(
                from: ethWallet.ethAddress,
                to: address ?? ethWallet.ethAddress,
                amount: "\(ethWallet.balance)"
            ).transaction
        }.get()
        
        return try await erc20ApiService.requestWeb3(waitsForConnectivity: false) { web3 in
            try await web3.eth.estimateGas(for: transaction)
        }.get()
    }
    
    private func markBalanceAsFresh() {
        ethWallet?.isBalanceInitialized = true
        
        balanceInvalidationSubscription = Task { [weak self] in
            try await Task.sleep(interval: Self.balanceLifetime, pauseInBackground: true)
            guard let self, let wallet = ethWallet else { return }
            wallet.isBalanceInitialized = false
            
            NotificationCenter.default.post(
                name: walletUpdatedNotification,
                object: self,
                userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
            )
        }.eraseToAnyCancellable()
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension ERC20WalletService {
    func initWallet(withPassphrase passphrase: String) async throws -> WalletAccount {
        
        // MARK: 1. Prepare
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        // MARK: 2. Create keys and addresses
        let keystore: BIP32Keystore
        do {
            guard let store = try BIP32Keystore(mnemonics: passphrase, password: EthWalletService.walletPassword, mnemonicsPassword: "", language: .english, prefixPath: EthWalletService.walletPath) else {
                throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
            }
            
            keystore = store
        } catch {
            throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: error)
        }
        
        await erc20ApiService.setKeystoreManager(.init([keystore]))
        
        guard let ethAddress = keystore.addresses?.first else {
            throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
        }
        
        // MARK: 3. Update
        let eWallet = EthWallet(
            unicId: tokenUnicID,
            address: ethAddress.address,
            ethAddress: ethAddress,
            keystore: keystore
        )
        ethWallet = eWallet
        
        if !enabled {
            enabled = true
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        NotificationCenter.default.post(
            name: walletUpdatedNotification,
            object: self,
            userInfo: [AdamantUserInfoKey.WalletService.wallet: eWallet]
        )
        
        self.setState(.upToDate, silent: true)
        Task {
            await update()
        }
        return eWallet
    }
    
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        ethWallet = nil
    }
}

// MARK: - Dependencies
extension ERC20WalletService: SwinjectDependentService {
    @MainActor
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(AdamantApiServiceProtocol.self)
        dialogService = container.resolve(DialogService.self)
        increaseFeeService = container.resolve(IncreaseFeeService.self)
        erc20ApiService = container.resolve(ERC20ApiService.self)
        vibroService = container.resolve(VibroService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
    }
}

// MARK: - Balances & addresses
extension ERC20WalletService {
    func getTransaction(by hash: String, waitsForConnectivity: Bool) async throws -> EthTransaction {
        let sender = wallet?.address
        let isOutgoing: Bool
        
        // MARK: 1. Transaction details
        let details: Web3Core.TransactionDetails = try await erc20ApiService.requestWeb3(
            waitsForConnectivity: waitsForConnectivity
        ) { web3 in
            try await web3.eth.transactionDetails(hash)
        }.get()
        
        let receipt = try await erc20ApiService.requestWeb3(
            waitsForConnectivity: waitsForConnectivity
        ) { web3 in
            try await web3.eth.transactionReceipt(hash)
        }.get()
        
        // MARK: 3. Check if transaction is delivered
        guard receipt.status == .ok,
              let blockNumber = details.blockNumber
        else {
            let transaction = details.transaction.asEthTransaction(
                date: nil,
                gasUsed: receipt.gasUsed,
                gasPrice: receipt.effectiveGasPrice,
                blockNumber: nil,
                confirmations: nil,
                receiptStatus: receipt.status,
                isOutgoing: false
            )
            return transaction
        }
        
        // MARK: 4. Block timestamp & confirmations
        let currentBlock = try await erc20ApiService.requestWeb3(
            waitsForConnectivity: waitsForConnectivity
        ) { web3 in
            try await web3.eth.blockNumber()
        }.get()
        
        let block = try await erc20ApiService.requestWeb3(
            waitsForConnectivity: waitsForConnectivity
        ) { web3 in
            try await web3.eth.block(by: receipt.blockHash)
        }.get()
        
        guard currentBlock >= blockNumber else {
            throw WalletServiceError.remoteServiceError(
                message: "ERC20 confirmations calculating error"
            )
        }
        
        let confirmations = currentBlock - blockNumber
        
        let transaction = details.transaction
        
        if let sender = sender {
            isOutgoing = transaction.sender?.address == sender
        } else {
            isOutgoing = false
        }
        
        let ethTransaction = transaction.asEthTransaction(
            date: block.timestamp,
            gasUsed: receipt.gasUsed,
            gasPrice: receipt.effectiveGasPrice,
            blockNumber: String(blockNumber),
            confirmations: String(confirmations),
            receiptStatus: receipt.status,
            isOutgoing: isOutgoing,
            for: self.token
        )
        
        return ethTransaction
    }
    
    func getBalance(address: String) async throws -> Decimal {
        guard let address = EthereumAddress(address) else {
            throw WalletServiceError.internalError(message: "Incorrect address", error: nil)
        }
        
        return try await getBalance(forAddress: address)
    }
    
    func getBalance(forAddress address: EthereumAddress) async throws -> Decimal {
        let exponent = -token.naturalUnits
        
        let balance = try await erc20ApiService.requestERC20(token: token) { erc20 in
            try await erc20.getBalance(account: address)
        }.get()
        
        let value = balance.asDecimal(exponent: exponent)
        return value
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        let result = try await apiService.get(key: EthWalletService.kvsAddress, sender: address)
            .mapError { $0.asWalletServiceError() }
            .get()
        
        guard let result = result else {
            throw WalletServiceError.walletNotInitiated
        }
        
        cachedWalletAddress[address] = result
        
        return result
    }
}

extension ERC20WalletService {
    func getTransactionsHistory(
        address: String,
        offset: Int = .zero,
        limit: Int = 100
    ) async throws -> [EthTransactionShort] {
        guard let address = self.ethWallet?.address else {
            throw WalletServiceError.internalError(message: "Can't get address", error: nil)
        }
        
        // Request
        let request = "(txto.eq.\(token.contractAddress),or(txfrom.eq.\(address.lowercased()),contract_to.eq.000000000000000000000000\(address.lowercased().replacingOccurrences(of: "0x", with: ""))))"
        
        // MARK: Request
        let txQueryParameters = [
            "limit": String(limit),
            "and": request,
            "offset": String(offset),
            "order": "time.desc"
        ]
        
        var transactions: [EthTransactionShort] = try await erc20ApiService.requestApiCore(waitsForConnectivity: false) { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: EthWalletService.transactionsListApiSubpath,
                method: .get,
                parameters: txQueryParameters,
                encoding: .url
            )
        }.get()
        
        transactions.sort { $0.date.compare($1.date) == .orderedDescending }
        return transactions
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
        
        let trs = try await getTransactionsHistory(
            address: address,
            offset: offset,
            limit: limit
        )
        
        guard trs.count > 0 else {
            hasMoreOldTransactions = false
            return []
        }
        
        let newTrs = trs.map { transaction in
            let isOutgoing = transaction.from == address
            let exponent = -token.naturalUnits
            
            return SimpleTransactionDetails(
                txId: transaction.hash,
                senderAddress: transaction.from,
                recipientAddress: transaction.to,
                dateValue: transaction.date,
                amountValue: transaction.contract_value.asDecimal(exponent: exponent),
                feeValue: transaction.gasUsed * transaction.gasPrice,
                confirmationsValue: nil,
                blockValue: nil,
                isOutgoing: isOutgoing,
                transactionStatus: TransactionStatus.notInitiated,
                nonceRaw: nil
            )
        }
        
        return newTrs
    }
    
    func getLocalTransactionHistory() -> [TransactionDetails] {
        historyTransactions
    }
    
    func updateStatus(for id: String, status: TransactionStatus?) {
        coinStorage.updateStatus(for: id, status: status)
    }
}
