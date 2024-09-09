//
//  EthWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import web3swift
import Swinject
import Alamofire
import BigInt
import Web3Core
import Combine
import CommonKit

struct EthWalletStorage {
    let keystore: BIP32Keystore
    let unicId: String
    
    func getWallet() -> EthWallet? {
        guard let ethAddress = keystore.addresses?.first else {
            return nil
        }
        
        return EthWallet(
            unicId: unicId,
            address: ethAddress.address,
            ethAddress: ethAddress,
            keystore: keystore
        )
    }
}

extension Web3Error {
    func asWalletServiceError() -> WalletServiceError {
        switch self {
        case .connectionError:
            return .networkError
            
        case .nodeError(let message):
            return .remoteServiceError(message: message)
            
        case .generalError(_ as URLError):
            return .networkError
            
        case .generalError(let error),
             .keystoreError(let error as Error):
            return .internalError(message: error.localizedDescription, error: error)
            
        case .inputError(let message), .processingError(let message):
            return .internalError(message: message, error: nil)
            
        case .transactionSerializationError,
             .dataError,
             .walletError,
             .unknownError,
             .typeError:
            return .internalError(message: "Unknown error", error: nil)
        case .valueError(desc: let desc):
            return .internalError(message: "Unknown error \(String(describing: desc))", error: nil)
        case .serverError(code: let code):
            return .remoteServiceError(message: "Unknown error \(code)")
        case .clientError(code: let code):
            return .internalError(message: "Unknown error \(code)", error: nil)
        }
    }
}

final class EthWalletService: WalletCoreProtocol {
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
	
	static let currencyLogo = UIImage.asset(named: "ethereum_wallet") ?? .init()
    
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
	
    static var tokenNetworkSymbol: String {
        return "ERC20"
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
    
    var nodeGroups: [NodeGroup] {
        [.eth]
    }
    
    @Atomic private(set) var isDynamicFee: Bool = true
    @Atomic private(set) var transactionFee: Decimal = 0.0
    @Atomic private(set) var gasPrice: BigUInt = 0
    @Atomic private(set) var gasLimit: BigUInt = 0
    @Atomic private(set) var isWarningGasPrice = false
	
	static let transferGas: Decimal = 21000
	static let kvsAddress = "eth:address"
    
    static let walletPath = "m/44'/60'/3'/1"
    static let walletPassword = ""
    
    // MARK: - Dependencies
    weak var accountService: AccountService?
    var apiService: AdamantApiServiceProtocol!
    var ethApiService: EthApiService!
    var dialogService: DialogService!
    var increaseFeeService: IncreaseFeeService!
    var vibroService: VibroService!
    var coreDataStack: CoreDataStack!
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.ethWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.ethWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.ethWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.ethWallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "eth_transaction"
    
	// MARK: - Properties
	
    public static let transactionsListApiSubpath = "ethtxs"
    @Atomic private(set) var enabled = true
    @Atomic private var subscriptions = Set<AnyCancellable>()
    @Atomic private var cachedWalletAddress: [String: String] = [:]
    
    @ObservableValue private(set) var historyTransactions: [TransactionDetails] = []
    @ObservableValue private(set) var hasMoreOldTransactions: Bool = true

    var transactionsPublisher: AnyObservable<[TransactionDetails]> {
        $historyTransactions.eraseToAnyPublisher()
    }
    
    var hasMoreOldTransactionsPublisher: AnyObservable<Bool> {
        $hasMoreOldTransactions.eraseToAnyPublisher()
    }
    
    var hasActiveNode: Bool {
        apiService.hasActiveNode
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
    
    @Atomic private(set) var ethWallet: EthWallet?
    @Atomic private var walletStorage: EthWalletStorage?
    
    var wallet: WalletAccount? { return ethWallet }
    
    // MARK: - Delayed KVS save
    @Atomic private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Logic
    init() {
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
                self?.ethWallet = nil
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
                self?.coinStorage.clear()
                self?.hasMoreOldTransactions = true
                self?.historyTransactions = []
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
    
    func getWallet() async -> EthWallet? {
        if let wallet = ethWallet {
            return wallet
        }
        
        guard let storage = walletStorage else { return nil }
        return storage.getWallet()
    }
    
    func update() {
        Task {
            await update()
        }
    }
    
    @MainActor
    func update() async {
        guard let wallet = await getWallet() else {
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
                NotificationCenter.default.post(name: notification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
            }
        }
        
        setState(.upToDate)
		
        await calculateFee()
	}
    
    func calculateFee(for address: EthereumAddress? = nil) async {
        let priceRaw = try? await getGasPrices()
        let gasLimitRaw = try? await getGasLimit(to: address)
        
        var price = priceRaw ?? defaultGasPriceGwei.toWei()
        var gasLimit = gasLimitRaw ?? defaultGasLimit
        
        let pricePercent = price * reliabilityGasPricePercent / 100
        let gasLimitPercent = gasLimit * reliabilityGasLimitPercent / 100
        
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
        
        isWarningGasPrice = gasPrice >= warningGasPriceGwei.toWei()
        self.gasLimit = gasLimit
        
        NotificationCenter.default.post(name: transactionFeeUpdated, object: self, userInfo: nil)
    }
	
	// MARK: - Tools
	
	func validate(address: String) -> AddressValidationResult {
		return addressRegex.perfectMatch(with: address) ? .valid : .invalid(description: nil)
	}
	
	func getGasPrices() async throws -> BigUInt {
        try await ethApiService.requestWeb3 { web3 in
            try await web3.eth.gasPrice()
        }.get()
	}
    
    func getGasLimit(to address: EthereumAddress?) async throws -> BigUInt {
        guard let ethWallet = ethWallet else { throw WalletServiceError.internalError(.endpointBuildFailed) }
        var transaction: CodableTransaction = .emptyTransaction
        transaction.from = ethWallet.ethAddress
        transaction.to = address ?? ethWallet.ethAddress
        
        return try await ethApiService.requestWeb3 { [transaction] web3 in
            try await web3.eth.estimateGas(for: transaction)
        }.get()
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension EthWalletService {
    func initWallet(withPassphrase passphrase: String) async throws -> WalletAccount {
        guard let adamant = accountService?.account else {
            throw WalletServiceError.notLogged
        }
        
        // MARK: 1. Prepare
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        // MARK: 2. Create keys and addresses
        do {
            guard let store = try BIP32Keystore(mnemonics: passphrase,
                                                password: EthWalletService.walletPassword,
                                                mnemonicsPassword: "",
                                                language: .english,
                                                prefixPath: EthWalletService.walletPath
            ) else {
                throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
            }
            
            walletStorage = .init(keystore: store, unicId: tokenUnicID)
            await ethApiService.setKeystoreManager(.init([store]))
        } catch {
            throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: error)
        }
        
        let eWallet = walletStorage?.getWallet()
        
        guard let eWallet = eWallet else {
            throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
        }
        
        // MARK: 3. Update
        ethWallet = eWallet
        
        NotificationCenter.default.post(
            name: walletUpdatedNotification,
            object: self,
            userInfo: [AdamantUserInfoKey.WalletService.wallet: eWallet]
        )
        
        if !enabled {
            enabled = true
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        // MARK: 4. Save into KVS
        let service = self
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            if eWallet.address.caseInsensitiveCompare(address) != .orderedSame {
                service.save(ethAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(ethAddress: eWallet.address.lowercased(), result: result)
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
                
                service.save(ethAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(ethAddress: eWallet.address, result: result)
                }
                
                return eWallet
                
            default:
                service.setState(.upToDate)
                throw error
            }
        }
    }
    
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        ethWallet = nil
    }
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(ethAddress: String, result: WalletServiceSimpleResult) {
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
                    guard let balance = self?.accountService?.account?.balance, balance > AdamantApiService.KvsFee else {
                        return
                    }
                    
                    self?.save(ethAddress: ethAddress) { result in
                        self?.kvsSaveCompletionRecursion(ethAddress: ethAddress, result: result)
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

// MARK: - Dependencies
extension EthWalletService: SwinjectDependentService {
    @MainActor
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(AdamantApiServiceProtocol.self)
        dialogService = container.resolve(DialogService.self)
        increaseFeeService = container.resolve(IncreaseFeeService.self)
        ethApiService = container.resolve(EthApiService.self)
        vibroService = container.resolve(VibroService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
    }
}

// MARK: - Balances & addresses
extension EthWalletService {
    func getBalance(address: String) async throws -> Decimal {
        guard let address = EthereumAddress(address) else {
            throw WalletServiceError.internalError(message: "Incorrect address", error: nil)
        }
        
        return try await getBalance(forAddress: address)
    }
    
	func getBalance(forAddress address: EthereumAddress) async throws -> Decimal {
        let balance = try await ethApiService.requestWeb3 { web3 in
            try await web3.eth.getBalance(for: address)
        }.get()
        
        return balance.asDecimal(exponent: EthWalletService.currencyExponent)
	}
	
	func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        do {
            let result = try await apiService.get(key: EthWalletService.kvsAddress, sender: address).get()
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            cachedWalletAddress[address] = result
            
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "ETH Wallet: failed to get address from KVS"
            )
        }
	}
}

// MARK: - KVS
extension EthWalletService {
    /// - Parameters:
    ///   - ethAddress: Ethereum address to save into KVS
    ///   - adamantAddress: Owner of Ethereum address
    ///   - completion: success
    private func save(ethAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService?.account, let keypair = accountService?.keypair else {
            completion(.failure(error: .notLogged))
            return
        }
        
        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughMoney))
            return
        }
        
        Task {
            let result = await apiService.store(
                key: EthWalletService.kvsAddress,
                value: ethAddress,
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
}

// MARK: - Transactions
extension EthWalletService {
    func getTransaction(by hash: String) async throws -> EthTransaction {
        let sender = wallet?.address
        
        // MARK: 1. Transaction details
        let details = try await ethApiService.requestWeb3 { web3 in
            try await web3.eth.transactionDetails(hash)
        }.get()
        
        let isOutgoing: Bool
        if let sender = sender {
            isOutgoing = details.transaction.to.address != sender
        } else {
            isOutgoing = false
        }
        
        // MARK: 2. Transaction receipt
        do {
            let receipt = try await ethApiService.requestWeb3 { web3 in
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
                    isOutgoing: isOutgoing
                )
                return transaction
            }
            
            // MARK: 4. Block timestamp & confirmations
            let currentBlock = try await ethApiService.requestWeb3 { web3 in
                try await web3.eth.blockNumber()
            }.get()
            
            let block = try await ethApiService.requestWeb3 { web3 in
                try await web3.eth.block(by: receipt.blockHash)
            }.get()
            
            let confirmations = currentBlock - blockNumber
            
            let transaction = details.transaction.asEthTransaction(
                date: block.timestamp,
                gasUsed: receipt.gasUsed,
                gasPrice: receipt.effectiveGasPrice,
                blockNumber: String(blockNumber),
                confirmations: String(confirmations),
                receiptStatus: receipt.status,
                isOutgoing: isOutgoing,
                hash: details.transaction.txHash
            )
            
            return transaction
        } catch let error as Web3Error {
            switch error {
                // Transaction not delivired yet
            case .inputError, .nodeError:
                let transaction = details.transaction.asEthTransaction(
                    date: nil,
                    gasUsed: nil,
                    gasPrice: nil,
                    blockNumber: nil,
                    confirmations: nil,
                    receiptStatus: TransactionReceipt.TXStatus.notYetProcessed,
                    isOutgoing: isOutgoing
                )
                return transaction
                
            default:
                throw error
            }
        } catch _ as URLError {
            throw WalletServiceError.networkError
        } catch {
            throw error
        }
    }
    
    func getTransactionsHistory(
        address: String,
        offset: Int,
        limit: Int = 100
    ) async throws -> [EthTransactionShort] {
        let columns = "time,txfrom,txto,gas,gasprice,block,txhash,value"
        let order = "time.desc"
        
        let txFromQueryParameters = [
            "select": columns,
            "limit": String(limit),
            "txfrom": "eq.\(address)",
            "offset": String(offset),
            "order": order,
            "contract_to": "eq."
        ]
        
        let txToQueryParameters = [
            "select": columns,
            "limit": String(limit),
            "txto": "eq.\(address)",
            "offset": String(offset),
            "order": order,
            "contract_to": "eq."
        ]
        
        let transactionsFrom: [EthTransactionShort] = try await ethApiService.requestApiCore { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: EthWalletService.transactionsListApiSubpath,
                method: .get,
                parameters: txFromQueryParameters,
                encoding: .url
            )
        }.get()
        
        let transactionsTo: [EthTransactionShort] = try await ethApiService.requestApiCore { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: EthWalletService.transactionsListApiSubpath,
                method: .get,
                parameters: txToQueryParameters,
                encoding: .url
            )
        }.get()
        
        let transactions = transactionsFrom + transactionsTo
        return transactions.sorted { $0.date.compare($1.date) == .orderedDescending }
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
            return []
        }
        
        return trs.map { transaction in
            let isOutgoing: Bool = transaction.from == address
            return SimpleTransactionDetails(
                txId: transaction.hash,
                senderAddress: transaction.from,
                recipientAddress: transaction.to,
                dateValue: transaction.date,
                amountValue: transaction.value,
                feeValue: transaction.gasUsed * transaction.gasPrice,
                confirmationsValue: nil,
                blockValue: nil,
                isOutgoing: isOutgoing,
                transactionStatus: TransactionStatus.notInitiated,
                nonceRaw: nil
            )
        }
    }
    
    func getLocalTransactionHistory() -> [TransactionDetails] {
        historyTransactions
    }
    
    func updateStatus(for id: String, status: TransactionStatus?) {
        coinStorage.updateStatus(for: id, status: status)
    }
}

// MARK: - PrivateKey generator
extension EthWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Ethereum"
    }
    
    var rowImage: UIImage? {
        return .asset(named: "ethereum_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
            return nil
        }
        
        guard let keystore = try? BIP32Keystore(mnemonics: passphrase, password: EthWalletService.walletPassword, mnemonicsPassword: "", language: .english, prefixPath: EthWalletService.walletPath),
            let account = keystore.addresses?.first,
            let privateKeyData = try? keystore.UNSAFE_getPrivateKeyData(password: EthWalletService.walletPassword, account: account) else {
            return nil
        }
        
        return privateKeyData.toHexString()
    }
}
