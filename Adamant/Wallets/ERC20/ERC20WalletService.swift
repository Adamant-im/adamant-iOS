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
import PromiseKit

class ERC20WalletService: WalletService {
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
    
    private (set) var transactionFee: Decimal = 0.0
    private (set) var diplayTransactionFee: Decimal = 0.0
    
    var isTransactionFeeValid: Bool {
        return ethWallet?.balance ?? 0 > diplayTransactionFee
    }
    
    static let transferGas: Decimal = 21000
    static let kvsAddress = "eth:address"
    
    static let walletPath = "m/44'/60'/3'/1"
    static let walletPassword = ""
    
    // MARK: - Dependencies
    weak var accountService: AccountService?
    var apiService: ApiService!
    var dialogService: DialogService!
    var router: Router!
    
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
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.erc20WalletService", qos: .utility, attributes: [.concurrent])
    private (set) var enabled = true
    
    private var _ethNodeUrl: String?
    private var _web3: web3?
    var web3: web3? {
        if _web3 != nil {
            return _web3
        }
        guard let url = _ethNodeUrl else {
            return nil
        }
        return setupEthNode(with: url)
    }
    private var baseUrl: String!
    let stateSemaphore = DispatchSemaphore(value: 1)
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.wallet) as? ERC20WalletViewController else {
            fatalError("Can't get erc20WalletViewController")
        }
        
        vc.service = self
        return vc
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
    
    private (set) var contract: web3.web3contract?
    private var balanceObserver: NSObjectProtocol?
    
    init(token: ERC20Token) {
        self.token = token
        
        self.setState(.notInitiated)
        
        walletUpdatedNotification = Notification.Name("adamant.erc20Wallet.\(token.symbol).walletUpdated")
        serviceEnabledChanged = Notification.Name("adamant.erc20Wallet.\(token.symbol).enabledChanged")
        transactionFeeUpdated = Notification.Name("adamant.erc20Wallet.\(token.symbol).feeUpdated")
        serviceStateChanged = Notification.Name("adamant.erc20Wallet.\(token.symbol).stateChanged")
        
        // Notifications
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.ethWallet = nil
            self?.initialBalanceCheck = false
            if let balanceObserver = self?.balanceObserver {
                NotificationCenter.default.removeObserver(balanceObserver)
                self?.balanceObserver = nil
            }
        }
        
        guard let node = EthWalletService.nodes.randomElement() else {
            fatalError("Failed to get ETH endpoint")
        }
        let apiUrl = node.asString()
        _ethNodeUrl = apiUrl
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.setupEthNode(with: apiUrl)
        }
    }
    
    func setupEthNode(with apiUrl: String) -> web3? {
        guard
            let url = URL(string: apiUrl),
            let web3 = try? Web3.new(url),
            let token = self.token else {
            return nil
        }
        
        self._web3 = web3
        self.baseUrl = ERC20WalletService.buildBaseUrl(for: web3.provider.network)
        
        if let address = EthereumAddress(token.contractAddress) {
            self.contract = web3.contract(Web3.Utils.erc20ABI, at: address, abiVersion: 2)
            
            self.erc20 = ERC20(web3: web3, provider: web3.provider, address: address)
        }
        
        return web3
    }
    
    func update() {
        guard let wallet = ethWallet else {
            return
        }
        
        defer { stateSemaphore.signal() }
        stateSemaphore.wait()
        
        switch state {
        case .notInitiated, .updating, .initiationFailed:
            return
            
        case .upToDate:
            break
        }
        
        setState(.updating)
        
        getBalance(forAddress: wallet.ethAddress) { [weak self] result in
            if let stateSemaphore = self?.stateSemaphore {
                defer {
                    stateSemaphore.signal()
                }
                stateSemaphore.wait()
            }
            
            switch result {
            case .success(let balance):
                let notification: Notification.Name?
                
                if wallet.balance != balance {
                    wallet.balance = balance
                    notification = self?.walletUpdatedNotification
                    self?.initialBalanceCheck = false
                } else if let initialBalanceCheck = self?.initialBalanceCheck, initialBalanceCheck {
                    self?.initialBalanceCheck = false
                    notification = self?.walletUpdatedNotification
                } else {
                    notification = nil
                }
                
                if let notification = notification {
                    NotificationCenter.default.post(name: notification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                }
                
            case .failure(let error):
                switch error {
                case .networkError:
                    break
                    
                default:
                    print("\(error.localizedDescription)")
                }
            }
            
            self?.setState(.upToDate)
        }
        
        getGasPrices { [weak self] result in
            switch result {
            case .success(let price):
                guard let fee = self?.diplayTransactionFee else {
                    return
                }
                
                let newFee = price * EthWalletService.transferGas
                
                if fee != newFee {
                    self?.diplayTransactionFee = newFee
                    
                    if let notification = self?.transactionFeeUpdated {
                        NotificationCenter.default.post(name: notification, object: self, userInfo: nil)
                    }
                }
                
            case .failure:
                break
            }
        }
    }
    
    func validate(address: String) -> AddressValidationResult {
        return addressRegex.perfectMatch(with: address) ? .valid : .invalid
    }
    
    func getGasPrices(completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        guard let web3 = self.web3 else {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get Gas Price", error: nil)))
            return
        }
        web3.eth.getGasPricePromise().done { price in
            completion(.success(result: price.asDecimal(exponent: EthWalletService.currencyExponent)))
        }.catch { error in
            completion(.failure(error: .internalError(message: error.localizedDescription, error: error)))
        }
    }
    
    private static func buildBaseUrl(for network: Networks?) -> String {
        let suffix: String
        
        guard let network = network else {
            return "https://api.etherscan.io/api"
        }
        
        switch network {
        case .Mainnet:
            suffix = ""
            
        default:
            suffix = "-\(network)"
        }
        
        return "https://api\(suffix).etherscan.io/api"
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
    func initWallet(withPassphrase passphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void) {
        
        // MARK: 1. Prepare
        stateSemaphore.wait()
        
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        // MARK: 2. Create keys and addresses
        let keystore: BIP32Keystore
        do {
            guard let store = try BIP32Keystore(mnemonics: passphrase, password: EthWalletService.walletPassword, mnemonicsPassword: "", language: .english, prefixPath: EthWalletService.walletPath) else {
                completion(.failure(error: .internalError(message: "ETH Wallet: failed to create Keystore", error: nil)))
                stateSemaphore.signal()
                return
            }
            
            keystore = store
        } catch {
            completion(.failure(error: .internalError(message: "ETH Wallet: failed to create Keystore", error: error)))
            stateSemaphore.signal()
            return
        }
        
        web3?.addKeystoreManager(KeystoreManager([keystore]))
        
        guard let ethAddress = keystore.addresses?.first else {
            completion(.failure(error: .internalError(message: "ETH Wallet: failed to create Keystore", error: nil)))
            stateSemaphore.signal()
            return
        }
        
        // MARK: 3. Update
        let eWallet = EthWallet(address: ethAddress.address, ethAddress: ethAddress, keystore: keystore)
        ethWallet = eWallet
        
        if !enabled {
            enabled = true
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        stateSemaphore.signal()
        
        self.initialBalanceCheck = true
        self.setState(.upToDate, silent: true)
        self.update()
        completion(.success(result: eWallet))
    }
    
    func setInitiationFailed(reason: String) {
        stateSemaphore.wait()
        setState(.initiationFailed(reason: reason))
        ethWallet = nil
        stateSemaphore.signal()
    }
}

// MARK: - Dependencies
extension ERC20WalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
    }
}

// MARK: - Balances & addresses
extension ERC20WalletService {
    func getTransaction(by hash: String, completion: @escaping (WalletServiceResult<EthTransaction>) -> Void) {
        let sender = wallet?.address
        guard let eth = web3?.eth else {
            completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: nil)))
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            let isOutgoing: Bool
            let details: web3swift.TransactionDetails
            
            // MARK: 1. Transaction details
            do {
                details = try eth.getTransactionDetailsPromise(hash).wait()
            } catch let error as Web3Error {
                completion(.failure(error: error.asWalletServiceError()))
                return
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: error)))
                return
            }
            
            // MARK: 2. Transaction receipt
            do {
                let receipt = try eth.getTransactionReceiptPromise(hash).wait()
                
                // MARK: 3. Check if transaction is delivered
                guard receipt.status == .ok, let blockNumber = details.blockNumber else {
                    let transaction = details.transaction.asEthTransaction(date: nil, gasUsed: receipt.gasUsed, blockNumber: nil, confirmations: nil, receiptStatus: receipt.status, isOutgoing: false)
                    completion(.success(result: transaction))
                    return
                }
                
                // MARK: 4. Block timestamp & confirmations
                let currentBlock = try eth.getBlockNumberPromise().wait()
                let block = try eth.getBlockByNumberPromise(blockNumber).wait()
                let confirmations = currentBlock - blockNumber
                
                let transaction = details.transaction
                
                if let sender = sender {
                    isOutgoing = transaction.sender?.address == sender
                } else {
                    isOutgoing = false
                }
                
                let ethTransaction = transaction.asEthTransaction(date: block.timestamp, gasUsed: receipt.gasUsed, blockNumber: String(blockNumber), confirmations: String(confirmations), receiptStatus: receipt.status, isOutgoing: isOutgoing, for: self.token)
                
                completion(.success(result: ethTransaction))
            } catch let error as Web3Error {
                let result: WalletServiceResult<EthTransaction>
                
                switch error {
                // Transaction not delivered yet
                case .inputError, .nodeError:
                    let transaction = details.transaction.asEthTransaction(date: nil, gasUsed: nil, blockNumber: nil, confirmations: nil, receiptStatus: TransactionReceipt.TXStatus.notYetProcessed, isOutgoing: false)
                    result = .success(result: transaction)
                    
                default:
                    result = .failure(error: error.asWalletServiceError())
                }
                
                completion(result)
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "Failed to get transaction", error: error)))
            }
        }
    }
    
    func getBalance(forAddress address: EthereumAddress, completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let address = self?.ethWallet?.address, let walletAddress = EthereumAddress(address), let erc20 = self?.erc20 else {
                print("Can't get address")
                return
            }

            var exponent = EthWalletService.currencyExponent
            if let naturalUnits = self?.token?.naturalUnits {
                exponent = -1 * naturalUnits
            }
            
            do {
                let balance = try erc20.getBalance(account: walletAddress)
                let value = balance.asDecimal(exponent: exponent)
                completion(.success(result:value))
            } catch {
                completion(.failure(error: WalletServiceError.internalError(message: "ERC 20 Service - Fail to get balance", error: error)))
            }
        }
    }
    
    func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void) {
        apiService.get(key: EthWalletService.kvsAddress, sender: address) { (result) in
            switch result {
            case .success(let value):
                if let address = value {
                    completion(.success(result: address))
                } else {
                    completion(.failure(error: .walletNotInitiated))
                }

            case .failure(let error):
                completion(.failure(error: .internalError(message: "ETH Wallet: fail to get address from KVS", error: error)))
            }
        }
    }
}

extension ERC20WalletService {
    func getTransactionsHistory(address: String, offset: Int = 0, limit: Int = 100, completion: @escaping (WalletServiceResult<[EthTransactionShort]>) -> Void) {
        guard let node = EthWalletService.nodes.randomElement(), let url = node.asURL() else {
            fatalError("Failed to build ETH endpoint URL")
        }
        
        guard let address = self.ethWallet?.address, let contract = self.token?.contractAddress else {
            print("Can't get address")
            return
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
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
            completion(.failure(error: WalletServiceError.apiError(err)))
            return
        }
        
        // MARK: Sending requests
        
        let dispatchGroup = DispatchGroup()
        var error: WalletServiceError?
        
        var transactions = [EthTransactionShort]()
        let semaphore = DispatchSemaphore(value: 1)
        
        dispatchGroup.enter()
        AF.request(txEndpoint, method: .get, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            defer {
                dispatchGroup.leave()
            }
            
            switch response.result {
            case .success(let data):
                do {
                    let trs = try JSONDecoder().decode([EthTransactionShort].self, from: data)
                    
                    semaphore.wait()
                    defer { semaphore.signal() }
                    transactions.append(contentsOf: trs)
                } catch let err {
                    error = .internalError(message: "Failed to deserialize transactions", error: err)
                }
                
            case .failure:
                error = .networkError
            }
        }
        
        // MARK: Handle results
        // Go background, so we won't block mainthread with .wait()
        DispatchQueue.global(qos: .userInitiated).async {
            dispatchGroup.wait()
            
            if let error = error {
                completion(.failure(error: error))
                return
            }
            
            transactions.sort { $0.date.compare($1.date) == .orderedDescending }
            
            completion(.success(result: transactions))
        }
    }
}

extension ERC20WalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.transactionsList) as? ERC20TransactionsViewController else {
            fatalError("Can't get ERC20TransactionsViewController")
        }
        
        vc.walletService = self
        return vc
    }
}
