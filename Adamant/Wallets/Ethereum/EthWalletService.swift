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

struct EthWalletStorage {
    let keystore: BIP32Keystore

    func getWalet(with web3: Web3) -> EthWallet? {
        web3.addKeystoreManager(KeystoreManager([keystore]))
        
        guard let ethAddress = keystore.addresses?.first else {
            return nil
        }
        
        return EthWallet(address: ethAddress.address, ethAddress: ethAddress, keystore: keystore)
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

class EthWalletService: WalletService {
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
	
	static let currencyLogo = #imageLiteral(resourceName: "ethereum_wallet")
    
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
	
    var tokenNetworkSymbol: String {
        return "ERC20"
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

    var isSupportIncreaseFee: Bool {
        return true
    }
    
    var isIncreaseFeeEnabled: Bool {
        return increaseFeeService.isIncreaseFeeEnabled(for: tokenUnicID)
    }
    
    private (set) var isDynamicFee: Bool = true
	private (set) var transactionFee: Decimal = 0.0
    private (set) var gasPrice: BigUInt = 0
    private (set) var gasLimit: BigUInt = 0
    private (set) var isWarningGasPrice = false
	
	static let transferGas: Decimal = 21000
	static let kvsAddress = "eth:address"
    
    static let walletPath = "m/44'/60'/3'/1"
    static let walletPassword = ""
    
    // MARK: - Dependencies
    weak var accountService: AccountService?
    var apiService: ApiService!
    var dialogService: DialogService!
    var router: Router!
    var increaseFeeService: IncreaseFeeService!
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.ethWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.ethWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.ethWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.ethWallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "eth_transaction"
    
	// MARK: - Properties
	
    public static let transactionsListApiSubpath = "ethtxs"
    
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
    
    private (set) var enabled = true
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.wallet) as? EthWalletViewController else {
            fatalError("Can't get EthWalletViewController")
        }
        
        vc.service = self
        return vc
    }
    
    private var initialBalanceCheck = false
    private var subscriptions = Set<AnyCancellable>()

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
    private var waletStorage: EthWalletStorage?
    
    var wallet: WalletAccount? { return ethWallet }
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol?
    
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
                self?.initialBalanceCheck = false
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
            }
            .store(in: &subscriptions)
    }
    
    func initiateNetwork(apiUrl: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        Task {
            self._ethNodeUrl = apiUrl
            guard await self.setupEthNode(with: apiUrl) != nil else {
                completion(.failure(error: WalletServiceError.networkError))
                return
            }
        }
    }
    
    func setupEthNode(with apiUrl: String) async -> Web3? {
        guard let url = URL(string: apiUrl),
              let web3 = try? await Web3.new(url) else {
            return nil
        }
        
        self._web3 = web3
        
        return web3
    }
    
    func getWallet() async -> EthWallet? {
        if let wallet = ethWallet {
            return wallet
        }
        guard let storage = waletStorage,
              let web3 = await web3
        else {
            return nil
        }
        return storage.getWalet(with: web3)
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
		return addressRegex.perfectMatch(with: address) ? .valid : .invalid
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
              let ethWallet = ethWallet
        else {
            throw WalletServiceError.internalError(message: "Can't get web3 service", error: nil)
        }
        
        do {
            var transaction: CodableTransaction = .emptyTransaction
            transaction.from = ethWallet.ethAddress
            transaction.to = address ?? ethWallet.ethAddress
            
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
extension EthWalletService: InitiatedWithPassphraseService {
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
            
            waletStorage = .init(keystore: store)
        } catch {
            throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: error)
        }
        
        guard let web3 = await web3,
              let eWallet = waletStorage?.getWalet(with: web3)
        else {
            throw WalletServiceError.internalError(message: "ETH Wallet: failed to create Keystore", error: nil)
        }
        
        // MARK: 3. Update
        ethWallet = eWallet
        
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
            
            service.initialBalanceCheck = true
            service.setState(.upToDate, silent: true)
            
            Task {
                await service.update()
            }
            
            return eWallet
        } catch let error as WalletServiceError {
            switch error {
            case .walletNotInitiated:
                // Show '0' without waiting for balance update
                if let wallet = service.ethWallet {
                    wallet.isBalanceInitialized = true
                    NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                }
                
                service.save(ethAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(ethAddress: eWallet.address, result: result)
                }
                service.setState(.upToDate)
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
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
        increaseFeeService = container.resolve(IncreaseFeeService.self)
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
        guard let web3 = await self.web3 else {
            throw WalletServiceError.internalError(message: "Can't get web3 service", error: nil)
        }
        
        do {
            let balance = try await web3.eth.getBalance(for: address)
            return balance.asDecimal(exponent: EthWalletService.currencyExponent)
        } catch {
            throw WalletServiceError.remoteServiceError(message: error.localizedDescription)
        }
	}
	
	func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        do {
            let result = try await apiService.get(key: EthWalletService.kvsAddress, sender: address)
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
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
        
        apiService.store(key: EthWalletService.kvsAddress, value: ethAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
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
        guard let eth = await web3?.eth else {
            throw WalletServiceError.internalError(message: "Failed to get transaction", error: nil)
        }
        
        let isOutgoing: Bool
        let details: Web3Core.TransactionDetails
        
        // MARK: 1. Transaction details
        do {
            details = try await eth.transactionDetails(hash)
            
            if let sender = sender {
                isOutgoing = details.transaction.to.address != sender
            } else {
                isOutgoing = false
            }
        } catch let error as Web3Error {
            throw error.asWalletServiceError()
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
                    isOutgoing: isOutgoing
                )
                return transaction
            }
            
            // MARK: 4. Block timestamp & confirmations
            let currentBlock = try await eth.blockNumber()
            let block = try await eth.block(by: receipt.blockHash)
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
                throw error.asWalletServiceError()
            }
        } catch {
            throw WalletServiceError.remoteServiceError(message: "Failed to get transaction")
        }
    }
    
    func getTransactionsHistory(address: String, offset: Int = 0, limit: Int = 100) async throws -> [EthTransactionShort] {
        guard let node = EthWalletService.nodes.randomElement(), let url = node.asURL() else {
            fatalError("Failed to build ETH endpoint URL")
        }
        
        // Request
        let columns = "time,txfrom,txto,gas,gasprice,block,txhash,value"
        let order = "time.desc"
        
        // MARK: Request txFrom
        let txFromQueryItems: [URLQueryItem] = [URLQueryItem(name: "select", value: columns),
                                                URLQueryItem(name: "limit", value: String(limit)),
                                                URLQueryItem(name: "txfrom", value: "eq.\(address)"),
                                                URLQueryItem(name: "offset", value: String(offset)),
                                                URLQueryItem(name: "order", value: order),
                                                URLQueryItem(name: "contract_to", value: "eq.")
        ]
        
        let txFromEndpoint: URL
        do {
            txFromEndpoint = try buildUrl(url: url.appendingPathComponent(EthWalletService.transactionsListApiSubpath), queryItems: txFromQueryItems)
        } catch {
            let err = AdamantApiService.InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            throw WalletServiceError.apiError(err)
        }
        
        // MARK: Request txTo
        let txToQueryItems: [URLQueryItem] = [URLQueryItem(name: "select", value: columns),
                                              URLQueryItem(name: "limit", value: String(limit)),
                                              URLQueryItem(name: "txto", value: "eq.\(address)"),
                                              URLQueryItem(name: "offset", value: String(offset)),
                                              URLQueryItem(name: "order", value: order),
                                              URLQueryItem(name: "contract_to", value: "eq.")
        ]
        
        let txToEndpoint: URL
        do {
            txToEndpoint = try buildUrl(url: url.appendingPathComponent(EthWalletService.transactionsListApiSubpath), queryItems: txToQueryItems)
        } catch {
            let err = AdamantApiService.InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            throw WalletServiceError.apiError(err)
        }
        
        // MARK: Sending requests
        
        var transactions = [EthTransactionShort]()
        
        let transactionsFrom: [EthTransactionShort] = try await apiService.sendRequest(url: txFromEndpoint, method: .get, parameters: nil)
        transactions.append(contentsOf: transactionsFrom)
        
        let transactionsTo: [EthTransactionShort] = try await apiService.sendRequest(url: txToEndpoint, method: .get, parameters: nil)
        transactions.append(contentsOf: transactionsTo)
        
        transactions.sort { $0.date.compare($1.date) == .orderedDescending }
        return transactions
    }
}

// MARK: - PrivateKey generator
extension EthWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Ethereum"
    }
    
    var rowImage: UIImage? {
        return #imageLiteral(resourceName: "ethereum_wallet_row")
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
