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
import struct BigInt.BigUInt
import Web3Core
import Combine
import CommonKit

final class ERC20WalletService: WalletService {
    // MARK: - Constants
    let addressRegex = try! NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
    
    static var currencySymbol: String = ""
    static var currencyLogo: UIImage = UIImage()
    static var qqPrefix: String = ""
    
    var minBalance: Decimal = 0
    var minAmount: Decimal = 0
    
    var tokenSymbol: String {
        return token?.symbol ?? ""
    }
    
    var tokenName: String {
        return token?.name ?? ""
    }
    
    var tokenLogo: UIImage {
        return token?.logo ?? UIImage()
    }
    
    var tokenNetworkSymbol: String {
        return "ERC20"
    }
    
    var consistencyMaxTime: Double {
        return 1200
    }
    
    var tokenContract: String {
        return token?.contractAddress ?? ""
    }
   
    var tokenUnicID: String {
        return tokenNetworkSymbol + tokenSymbol + tokenContract
    }
    
    var defaultVisibility: Bool {
        return token?.defaultVisibility ?? false
    }
    
    var defaultOrdinalLevel: Int? {
        return token?.defaultOrdinalLevel
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
    
    private (set) var blockchainSymbol: String = "ETH"
    private (set) var isDynamicFee: Bool = true
    private (set) var transactionFee: Decimal = 0.0
    private (set) var gasPrice: BigUInt = 0
    private (set) var gasLimit: BigUInt = 0
    private (set) var isWarningGasPrice = false
    
    var isTransactionFeeValid: Bool {
        return ethWallet?.balance ?? 0 > transactionFee
    }
    
    static let transferGas: Decimal = 21000
    static let kvsAddress = "eth:address"
    
    static let walletPath = "m/44'/60'/3'/1"
    static let walletPassword = ""
    
    // MARK: - Dependencies
    weak var accountService: AccountService?
    var apiService: ApiService!
    var dialogService: DialogService!
    var increaseFeeService: IncreaseFeeService!
    var coreDataStack: CoreDataStack!
    
    // MARK: - Notifications
    var walletUpdatedNotification = Notification.Name("adamant.erc20Wallet.walletUpdated")
    var serviceEnabledChanged = Notification.Name("adamant.erc20Wallet.enabledChanged")
    var transactionFeeUpdated = Notification.Name("adamant.erc20Wallet.feeUpdated")
    var serviceStateChanged = Notification.Name("adamant.erc20Wallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "erc20_transaction"
    var dynamicRichMessageType: String {
        return "\(self.token?.symbol.lowercased() ?? "erc20")_transaction"
    }
    
    // MARK: - Properties
    
    private (set) var token: ERC20Token?
    private (set) var erc20: ERC20?
    private (set) var enabled = true
    
    private var subscriptions = Set<AnyCancellable>()
    private var _ethNodeUrl: String?
    private var _web3: Web3?
    var web3: Web3? {
        get async {
            if _web3 != nil {
                return _web3
            }
            guard let url = _ethNodeUrl else {
                return nil
            }
            
            return await setupEthNode(with: url)
        }
    }
    
    private var initialBalanceCheck = false
    
    // MARK: - State
    private (set) var state: WalletServiceState = .notInitiated
    
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
    
    private (set) var ethWallet: EthWallet?
    var wallet: WalletAccount? { return ethWallet }
    
    private (set) var contract: Web3.Contract?
    private var balanceObserver: NSObjectProtocol?
    
    @Published private(set) var historyTransactions: [CoinTransaction] = []
    @Published private(set) var hasMoreOldTransactions: Bool = true

    var transactionsPublisher: Published<[CoinTransaction]>.Publisher {
        $historyTransactions
    }
    
    var hasMoreOldTransactionsPublisher: Published<Bool>.Publisher {
        $hasMoreOldTransactions
    }
    
    lazy var coinStorage = AdamantCoinStorageService(
        coinId: tokenUnicID,
        coreDataStack: coreDataStack
    )
    
    init(token: ERC20Token) {
        self.token = token
        
        self.setState(.notInitiated)
        
        walletUpdatedNotification = Notification.Name("adamant.erc20Wallet.\(token.symbol).walletUpdated")
        serviceEnabledChanged = Notification.Name("adamant.erc20Wallet.\(token.symbol).enabledChanged")
        transactionFeeUpdated = Notification.Name("adamant.erc20Wallet.\(token.symbol).feeUpdated")
        serviceStateChanged = Notification.Name("adamant.erc20Wallet.\(token.symbol).stateChanged")
        
        // Notifications
        addObservers()
        
        guard let node = EthWalletService.nodes.randomElement() else {
            fatalError("Failed to get ETH endpoint")
        }
        let apiUrl = node.asString()
        _ethNodeUrl = apiUrl
        Task {
            _ = await self.setupEthNode(with: apiUrl)
        }
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
                self?.initialBalanceCheck = false
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
            }
            .store(in: &subscriptions)
    }
    
    func addTransactionObserver() {
        coinStorage.$transactions
            .removeDuplicates()
            .sink { [weak self] transactions in
                self?.historyTransactions = transactions
            }
            .store(in: &subscriptions)
    }
    
    func setupEthNode(with apiUrl: String) async -> Web3? {
        guard
            let url = URL(string: apiUrl),
            let web3 = try? await Web3.new(url),
            let token = self.token else {
            return nil
        }
        
        self._web3 = web3
        
        if let address = EthereumAddress(token.contractAddress) {
            self.contract = web3.contract(Web3.Utils.erc20ABI, at: address, abiVersion: 2)
            
            self.erc20 = ERC20(web3: web3, provider: web3.provider, address: address)
        }
        
        return web3
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
            wallet.isBalanceInitialized = true
            let notification: Notification.Name?
            
            if wallet.balance != balance {
                wallet.balance = balance
                notification = walletUpdatedNotification
                initialBalanceCheck = false
            } else if initialBalanceCheck {
                initialBalanceCheck = false
                notification = walletUpdatedNotification
            } else {
                notification = nil
            }
            
            if let notification = notification {
                NotificationCenter.default.post(name: notification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
            }
        }
        
        setState(.upToDate)
        
        await calculateFee()
    }
    
    func calculateFee(for address: EthereumAddress? = nil) async {
        guard let token = token else { return }

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
        guard let web3 = await self.web3 else {
            throw WalletServiceError.internalError(message: "Can't get web3 service", error: nil)
        }
        
        do {
            let price = try await web3.eth.gasPrice()
            return price
        } catch {
            throw WalletServiceError.remoteServiceError(
                message: error.localizedDescription
            )
        }
    }
    
    func getGasLimit(to address: EthereumAddress?) async throws -> BigUInt {
        guard let web3 = await self.web3,
              let ethWallet = ethWallet,
              let erc20 = erc20
        else {
            throw WalletServiceError.internalError(message: "Can't get web3 service", error: nil)
        }
        
        do {
            let transaction = try await erc20.transfer(
                from: ethWallet.ethAddress,
                to: address ?? ethWallet.ethAddress,
                amount: "\(ethWallet.balance)"
            ).transaction
            
            let price = try await web3.eth.estimateGas(for: transaction)
            return price
        } catch {
            throw WalletServiceError.remoteServiceError(
                message: error.localizedDescription
            )
        }
    }
    
    private func buildUrl(url: URL, queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw AdamantApiService.InternalError.endpointBuildFailed
        }
        
        components.queryItems = queryItems
        
        return try components.asURL()
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension ERC20WalletService: InitiatedWithPassphraseService {
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
        
        await web3?.addKeystoreManager(KeystoreManager([keystore]))
        
        guard let ethAddress = keystore.addresses?.first else {
            throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
        }
        
        // MARK: 3. Update
        let eWallet = EthWallet(address: ethAddress.address, ethAddress: ethAddress, keystore: keystore)
        ethWallet = eWallet
        
        if !enabled {
            enabled = true
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        self.initialBalanceCheck = true
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
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        increaseFeeService = container.resolve(IncreaseFeeService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
    }
}

// MARK: - Balances & addresses
extension ERC20WalletService {
    func getTransaction(by hash: String) async throws -> EthTransaction {
        let sender = wallet?.address
        guard let eth = await web3?.eth else {
            throw WalletServiceError.internalError(message: "Failed to get transaction", error: nil)
        }
        
        let isOutgoing: Bool
        let details: Web3Core.TransactionDetails
        
        // MARK: 1. Transaction details
        do {
            details = try await eth.transactionDetails(hash)
        } catch let error as Web3Error {
            throw error.asWalletServiceError()
        } catch _ as URLError {
            throw WalletServiceError.networkError
        } catch {
            throw WalletServiceError.remoteServiceError(message: "Failed to get transaction")
        }
        
        // MARK: 2. Transaction receipt
        do {
            let receipt = try await eth.transactionReceipt(hash)
            
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
            let currentBlock = try await eth.blockNumber()
            let block = try await eth.block(by: receipt.blockHash)
            
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
        } catch let error as Web3Error {
            switch error {
                // Transaction not delivered yet
            case .inputError, .nodeError:
                let transaction = details.transaction.asEthTransaction(
                    date: nil,
                    gasUsed: nil,
                    gasPrice: nil,
                    blockNumber: nil,
                    confirmations: nil,
                    receiptStatus: TransactionReceipt.TXStatus.notYetProcessed,
                    isOutgoing: false
                )
                return transaction
                
            default:
                throw error.asWalletServiceError()
            }
        } catch _ as URLError {
            throw WalletServiceError.networkError
        } catch {
            throw error
        }
    }
    
    func getBalance(address: String) async throws -> Decimal {
        guard let address = EthereumAddress(address) else {
            throw WalletServiceError.internalError(message: "Incorrect address", error: nil)
        }
        
        return try await getBalance(forAddress: address)
    }
    
    func getBalance(forAddress address: EthereumAddress) async throws -> Decimal {
        guard let erc20 = self.erc20 else {
            throw WalletServiceError.internalError(message: "Can't get address", error: nil)
        }
        
        var exponent = EthWalletService.currencyExponent
        if let naturalUnits = self.token?.naturalUnits {
            exponent = -1 * naturalUnits
        }
        
        do {
            let balance = try await erc20.getBalance(account: address)
            let value = balance.asDecimal(exponent: exponent)
            return value
        } catch {
            throw WalletServiceError.remoteServiceError(
                message: "ERC 20 Service - Fail to get balance"
            )
        }
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        do {
            let result = try await apiService.get(key: EthWalletService.kvsAddress, sender: address)
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            return result
        } catch {
            throw WalletServiceError.remoteServiceError(
                message: "ETH Wallet: failed to get address from KVS"
            )
        }
    }
}

extension ERC20WalletService {
    func getTransactionsHistory(address: String, offset: Int = 0, limit: Int = 100) async throws -> [EthTransactionShort] {
        guard let node = EthWalletService.nodes.randomElement(), let url = node.asURL() else {
            fatalError("Failed to build ETH endpoint URL")
        }
        
        guard let address = self.ethWallet?.address, let contract = self.token?.contractAddress else {
            throw WalletServiceError.internalError(message: "Can't get address", error: nil)
        }
        
        // Request
        let request = "(txto.eq.\(contract),or(txfrom.eq.\(address.lowercased()),contract_to.eq.000000000000000000000000\(address.lowercased().replacingOccurrences(of: "0x", with: ""))))"
        
        // MARK: Request
        let txQueryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: String(limit)),
                                            URLQueryItem(name: "and", value: request),
                                            URLQueryItem(name: "offset", value: String(offset)),
                                            URLQueryItem(name: "order", value: "time.desc")
        ]
        
        let txEndpoint: URL
        do {
            txEndpoint = try buildUrl(url: url.appendingPathComponent(EthWalletService.transactionsListApiSubpath), queryItems: txQueryItems)
        } catch {
            let err = AdamantApiService.InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            throw WalletServiceError.apiError(err)
        }
        
        // MARK: Sending requests
        
        var transactions: [EthTransactionShort] = try await apiService.sendRequest(url: txEndpoint, method: .get, parameters: nil)
        transactions.sort { $0.date.compare($1.date) == .orderedDescending }
        return transactions
    }
    
    func loadTransactions(offset: Int, limit: Int) async throws {
        guard let address = wallet?.address else {
            return
        }
        
        let trs = try await getTransactionsHistory(
            address: address,
            offset: offset,
            limit: limit
        )
        
        guard trs.count > 0 else {
            hasMoreOldTransactions = false
            return
        }
        
        let newTrs = trs.map { transaction in
            let isOutgoing: Bool = transaction.to != address
            
            var exponent = EthWalletService.currencyExponent
            if let naturalUnits = token?.naturalUnits {
                exponent = -1 * naturalUnits
            }
            
            return SimpleTransactionDetails(
                txId: transaction.hash,
                senderAddress: transaction.from,
                recipientAddress: transaction.to,
                dateValue: transaction.date,
                amountValue: transaction.contract_value.asDecimal(exponent: exponent),
                feeValue: nil,
                confirmationsValue: nil,
                blockValue: nil,
                isOutgoing: isOutgoing,
                transactionStatus: nil
            )
        }
        
        coinStorage.append(newTrs)
    }
}
