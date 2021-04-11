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
             .unknownError:
            return .internalError(message: "Unknown error", error: nil)
        }
    }
}

class EthWalletService: WalletService {
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
	
	static let currencySymbol = "ETH"
	static let currencyLogo = #imageLiteral(resourceName: "wallet_eth")
	static let currencyExponent = -18
    
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenName: String {
        return ""
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
	
	private (set) var transactionFee: Decimal = 0.0
	
	static let transferGas: Decimal = 21000
	static let kvsAddress = "eth:address"
    
    static let walletPath = "m/44'/60'/3'/1"
    static let walletPassword = ""
    
    // MARK: - Dependencies
    weak var accountService: AccountService!
    var apiService: ApiService!
    var dialogService: DialogService!
    var router: Router!
    
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.ethWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.ethWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.ethWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.ethWallet.stateChanged")
    
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "eth_transaction"
    let cellIdentifierSent = "ethTransferSent"
    let cellIdentifierReceived = "ethTransferReceived"
    let cellSource: CellSource? = CellSource.nib(nib: UINib(nibName: "TransferCollectionViewCell", bundle: nil))
    
	// MARK: - Properties
	
    public static let transactionsListApiSubpath = "ethtxs"
    
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
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.ethWalletService", qos: .utility, attributes: [.concurrent])
    private (set) var enabled = true
    
    let stateSemaphore = DispatchSemaphore(value: 1)
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.wallet) as? EthWalletViewController else {
            fatalError("Can't get EthWalletViewController")
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
    
    private (set) var ethWallet: EthWallet? = nil
    
    var wallet: WalletAccount? { return ethWallet }
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol? = nil
    
    // MARK: - Logic
    init() {
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
    }
    
    func initiateNetwork(apiUrl: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let _ = self.setupEthNode(with: apiUrl) else {
                completion(.failure(error: WalletServiceError.networkError))
                return
            }
        }
    }
    
    func setupEthNode(with apiUrl: String) -> web3? {
        guard let url = URL(string: apiUrl), let web3 = try? Web3.new(url) else {
            return nil
        }
        
        self._web3 = web3
        self.baseUrl = EthWalletService.buildBaseUrl(for: web3.provider.network)
        
        return web3
    }
    
    func update() {
        guard let wallet = ethWallet else {
            return
        }
        
        defer { stateSemaphore.signal() }
        stateSemaphore.wait()
        
        switch state {
        case .notInitiated, .updating, .initiationFailed(_):
            return
            
        case .upToDate:
            break
        }
        
        setState(.updating)
        
        getBalance(forAddress: wallet.ethAddress) { [weak self] result in
            defer { self?.stateSemaphore.signal() }
            
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
                print("\(error.localizedDescription)")
            }
            
            self?.setState(.upToDate)
		}
		
		getGasPrices { [weak self] result in
			switch result {
			case .success(let price):
				guard let fee = self?.transactionFee else {
					return
				}
				
				let newFee = price * EthWalletService.transferGas
				
				if fee != newFee {
					self?.transactionFee = newFee
					
					if let notification = self?.transactionFeeUpdated {
						NotificationCenter.default.post(name: notification, object: self, userInfo: nil)
					}
				}
				
			case .failure:
				break
			}
		}
	}
	
	// MARK: - Tools
	
	func validate(address: String) -> AddressValidationResult {
		return addressRegex.perfectMatch(with: address) ? .valid : .invalid
	}
	
	func getGasPrices(completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        web3?.eth.getGasPricePromise().done { price in
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
extension EthWalletService: InitiatedWithPassphraseService {
    func initWallet(withPassphrase passphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void) {
        guard let adamant = accountService.account else {
            completion(.failure(error: .notLogged))
            return
        }
        
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
        
        guard let web3 = web3 else { return }
        
        web3.addKeystoreManager(KeystoreManager([keystore]))
        
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
        
        // MARK: 4. Save into KVS
        getWalletAddress(byAdamantAddress: adamant.address) { [weak self] result in
            guard let service = self else {
                return
            }
            
            switch result {
            case .success(let address):
                // ETH already saved
                if ethAddress.address.caseInsensitiveCompare(address) != .orderedSame {
                    service.save(ethAddress: ethAddress.address) { result in
                        service.kvsSaveCompletionRecursion(ethAddress: ethAddress.address.lowercased(), result: result)
                    }
                }
                
                service.initialBalanceCheck = true
                service.setState(.upToDate, silent: true)
                service.update()
                
                completion(.success(result: eWallet))
                
            case .failure(let error):
                switch error {
                case .walletNotInitiated:
                    // Show '0' without waiting for balance update
                    if let wallet = service.ethWallet {
                        NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                    }
                    
                    service.save(ethAddress: ethAddress.address) { result in
                        service.kvsSaveCompletionRecursion(ethAddress: ethAddress.address, result: result)
                    }
                    service.setState(.upToDate)
                    completion(.success(result: eWallet))
                    
                default:
                    service.setState(.upToDate)
                    completion(.failure(error: error))
                }
            }
        }
    }
    
    func setInitiationFailed(reason: String) {
        stateSemaphore.wait()
        setState(.initiationFailed(reason: reason))
        ethWallet = nil
        stateSemaphore.signal()
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
                    guard let balance = self?.accountService.account?.balance, balance > AdamantApiService.KvsFee else {
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
    }
}


// MARK: - Balances & addresses
extension EthWalletService {
	func getBalance(forAddress address: EthereumAddress, completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
		DispatchQueue.global(qos: .utility).async { [weak self] in
			guard let web3 = self?.web3 else {
				print("Can't get web3 service")
				return
			}
			
			web3.eth.getBalancePromise(address: address).done { balance in
                completion(.success(result: balance.asDecimal(exponent: EthWalletService.currencyExponent)))
            }.catch { error in
                completion(.failure(error: .internalError(message: error.localizedDescription, error: error)))
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


// MARK: - KVS
extension EthWalletService {
    /// - Parameters:
    ///   - ethAddress: Ethereum address to save into KVS
    ///   - adamantAddress: Owner of Ethereum address
    ///   - completion: success
    private func save(ethAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
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
                
                if let sender = sender {
                    isOutgoing = details.transaction.to.address != sender
                } else {
                    isOutgoing = false
                }
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
                    let transaction = details.transaction.asEthTransaction(date: nil, gasUsed: receipt.gasUsed, blockNumber: nil, confirmations: nil, receiptStatus: receipt.status, isOutgoing: isOutgoing)
                    completion(.success(result: transaction))
                    return
                }
                
                // MARK: 4. Block timestamp & confirmations
                let currentBlock = try eth.getBlockNumberPromise().wait()
                let block = try eth.getBlockByNumberPromise(blockNumber).wait()
                let confirmations = currentBlock - blockNumber
                
                let transaction = details.transaction.asEthTransaction(date: block.timestamp, gasUsed: receipt.gasUsed, blockNumber: String(blockNumber), confirmations: String(confirmations), receiptStatus: receipt.status, isOutgoing: isOutgoing)
                
                completion(.success(result: transaction))
            } catch let error as Web3Error {
                let result: WalletServiceResult<EthTransaction>
                
                switch error {
                    // Transaction not delivired yet
                case .inputError, .nodeError:
                    let transaction = details.transaction.asEthTransaction(date: nil, gasUsed: nil, blockNumber: nil, confirmations: nil, receiptStatus: TransactionReceipt.TXStatus.notYetProcessed, isOutgoing: isOutgoing)
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
    
    func getTransactionsHistory(address: String, offset: Int = 0, limit: Int = 100, completion: @escaping (WalletServiceResult<[EthTransactionShort]>) -> Void) {
        guard let raw = AdamantResources.ethServers.randomElement(), let url = URL(string: raw) else {
            fatalError("Failed to build ETH endpoint URL")
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
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
            completion(.failure(error: WalletServiceError.apiError(err)))
            return
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
            completion(.failure(error: WalletServiceError.apiError(err)))
            return
        }
        
        // MARK: Sending requests
        
        let dispatchGroup = DispatchGroup()
        var error: WalletServiceError? = nil
        
        var transactions = [EthTransactionShort]()
        let semaphore = DispatchSemaphore(value: 1)
        
        dispatchGroup.enter() // Enter for txFrom
        Alamofire.request(txFromEndpoint, method: .get, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            defer {
                dispatchGroup.leave() // Exit for txFrom
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
        
        dispatchGroup.enter() // Enter for txTo
        Alamofire.request(txToEndpoint, method: .get, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            defer {
                dispatchGroup.leave() // Enter for txTo
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
    
    
    /// Transaction history for Ropsten testnet
    func getTransactionsHistoryRopsten(address: String, page: Int = 1, size: Int = 50, completion: @escaping (WalletServiceResult<[EthTransaction]>) -> Void) {
        let queryItems: [URLQueryItem] = [URLQueryItem(name: "module", value: "account"),
                                          URLQueryItem(name: "action", value: "txlist"),
                                          URLQueryItem(name: "address", value: address),
                                          URLQueryItem(name: "page", value: "\(page)"),
                                          URLQueryItem(name: "offset", value: "\(size)"),
                                          URLQueryItem(name: "sort", value: "desc")
            //                        ,URLQueryItem(name: "apikey", value: "YourApiKeyToken")
        ]
        
        let endpoint: URL
        do {
            endpoint = try buildUrl(url: URL(string: baseUrl)!, queryItems: queryItems)
        } catch {
            let err = AdamantApiService.InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(error: WalletServiceError.apiError(err)))
            return
        }
        
        Alamofire.request(endpoint).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let model: EthResponse = try JSONDecoder().decode(EthResponse.self, from: data)
                    
                    if model.status == 1 {
                        var transactions = model.result
                        
                        for index in 0..<transactions.count {
                            let from = transactions[index].from
                            transactions[index].isOutgoing = from == address
                        }
                        
                        completion(.success(result: transactions))
                    } else {
                        completion(.failure(error: .remoteServiceError(message: model.message)))
                    }
                } catch {
                    completion(.failure(error: .internalError(message: "Failed to deserialize transactions", error: error)))
                }
                
            case .failure:
                completion(.failure(error: .networkError))
            }
        }
    }
}

// MARK: - PrivateKey generator
extension EthWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Ethereum"
    }
    
    var rowImage: UIImage? {
        return #imageLiteral(resourceName: "wallet_eth_row")
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
