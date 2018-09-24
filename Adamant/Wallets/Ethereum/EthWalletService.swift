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

extension RichMessageType {
	static let ethTransfer = RichMessageType(stringValue: EthWalletService.richMessageType)
}


class EthWalletService: WalletService {
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^0x[a-fA-F0-9]{40}$")
	
	static let currencySymbol = "ETH"
	static let currencyLogo = #imageLiteral(resourceName: "wallet_eth")
	static let currencyExponent = -18
	
	private (set) var transactionFee: Decimal = 0.0
	
	static let transferGas: Decimal = 21000
	static let defaultGasPrice = 20000000000 // 20 Gwei
	static let kvsAddress = "eth:address"
	
	
	// MARK: - Dependencies
	weak var accountService: AccountService!
	var apiService: ApiService!
	var dialogService: DialogService!
	var router: Router!
	
	
	// MARK: - Notifications
	let walletUpdatedNotification = Notification.Name("adamant.ethWallet.walletUpdated")
	let serviceEnabledChanged = Notification.Name("adamant.ethWallet.enabledChanged")
	let transactionFeeUpdated: Notification.Name = Notification.Name("adamant.ethWallet.feeUpdated")
	
    
    // MARK: RichMessageHandler properties
    static let richMessageType = "eth_transaction"
    let cellIdentifier = "ethTransfer"
    let cellSource: CellSource? = CellSource.nib(nib: UINib(nibName: "TransferCollectionViewCell", bundle: nil))
    
    
	// MARK: - Properties
	
	let web3: web3
	private let baseUrl: String
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
	
	// MARK: - State
	private (set) var state: WalletServiceState = .notInitiated
	private (set) var ethWallet: EthWallet? = nil
	
	var wallet: WalletAccount? { return ethWallet }
	
	
	// MARK: - Logic
	init(apiUrl: String) throws {
		// Init network
		guard let url = URL(string: apiUrl), let web3 = Web3.new(url) else {
			throw WalletServiceError.networkError
		}
		
		self.web3 = web3
		self.baseUrl = EthWalletService.buildBaseUrl(for: web3.provider.network)
		
		// Notifications
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
			self?.update()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
			self?.update()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.ethWallet = nil
		}
	}
	
	func update() {
		guard let wallet = ethWallet else {
			return
		}
		
		defer { stateSemaphore.signal() }
		stateSemaphore.wait()
		
		switch state {
		case .notInitiated, .updating:
			return
			
		case .initiated, .updated:
			break
		}
		
		state = .updating
		
		getBalance(forAddress: wallet.ethAddress) { result in
			defer {
				self.stateSemaphore.signal()
			}
			self.stateSemaphore.wait()
			self.state = .updated
			
			switch result {
			case .success(let balance):
				if wallet.balance != balance {
					wallet.balance = balance
					NotificationCenter.default.post(name: self.walletUpdatedNotification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
				}
				
			case .failure(let error):
				self.dialogService.showRichError(error: error)
			}
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
		switch web3.eth.getGasPrice() {
		case .success(let price):
			completion(.success(result: price.asDecimal(exponent: EthWalletService.currencyExponent)))
			
		case .failure(let error):
			completion(.failure(error: error.asWalletServiceError()))
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
	
	private func buildUrl(queryItems: [URLQueryItem]? = nil) throws -> URL {
		guard let url = URL(string: baseUrl), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			throw AdamantApiService.InternalError.endpointBuildFailed
		}
		
		components.queryItems = queryItems
		
		return try components.asURL()
	}
}


// MARK: - WalletInitiatedWithPassphrase
extension EthWalletService: InitiatedWithPassphraseService {
	func initWallet(withPassphrase passphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void) {
		// MARK: 1. Prepare
		stateSemaphore.wait()
		
		state = .notInitiated
		
		if enabled {
			enabled = false
			NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
		}
		
		// MARK: 2. Create keys and addresses
		let keystore: BIP32Keystore
		do {
			guard let store = try BIP32Keystore(mnemonics: passphrase, password: "", mnemonicsPassword: "", language: .english) else {
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
		
		web3.addKeystoreManager(KeystoreManager([keystore]))
		
		guard let ethAddress = keystore.addresses?.first else {
			completion(.failure(error: .internalError(message: "ETH Wallet: failed to create Keystore", error: nil)))
			stateSemaphore.signal()
			return
		}
		
		// MARK: 3. Update
		ethWallet = EthWallet(address: ethAddress.address, ethAddress: ethAddress, keystore: keystore)
		state = .initiated
		
		if !enabled {
			enabled = true
			NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
		}
		
		stateSemaphore.signal()
		
		// MARK: 4. Save into KVS
		save(ethAddress: ethAddress.address) { [weak self] result in
			switch result {
			case .success:
				break
				
			case .failure(let error):
				self?.dialogService.showRichError(error: error)
			}
		}
		
		// MARK: 5. Initiate update
		update()
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
			
			let result = web3.eth.getBalance(address: address)
			
			switch result {
			case .success(let balance):
				completion(.success(result: balance.asDecimal(exponent: EthWalletService.currencyExponent)))
				
			case .failure(let error):
				completion(.failure(error: error.asWalletServiceError()))
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
		
		let api = apiService
		
		getWalletAddress(byAdamantAddress: adamant.address) { result in
			switch result {
			case .success(let address):
				guard address == ethAddress else {
					// ETH already saved
					completion(.success)
					return
				}
				
				guard adamant.balance >= AdamantApiService.KvsFee else {
					completion(.failure(error: .notEnoughtMoney))
					return
				}
				
				api?.store(key: EthWalletService.kvsAddress, value: ethAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
					switch result {
					case .success:
						completion(.success)
						
					case .failure(let error):
						completion(.failure(error: .apiError(error)))
					}
				}
				
			case .failure(let error):
				completion(.failure(error: error))
			}
		}
	}
}


// MARK: - Transactions
extension EthWalletService {
	func getTransactionsHistory(address: String, page: Int = 1, size: Int = 50, completion: @escaping (WalletServiceResult<[EthTransaction]>) -> Void) {
		let queryItems: [URLQueryItem] = [URLQueryItem(name: "module", value: "account"),
										  URLQueryItem(name: "action", value: "txlist"),
										  URLQueryItem(name: "address", value: address),
										  URLQueryItem(name: "page", value: "\(page)"),
										  URLQueryItem(name: "offset", value: "\(size)"),
										  URLQueryItem(name: "sort", value: "desc")
			//			            ,URLQueryItem(name: "apikey", value: "YourApiKeyToken")
		]
		
		let endpoint: URL
		do {
			endpoint = try buildUrl(queryItems: queryItems)
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
						completion(.success(result: model.result))
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
	
	func getTransaction(byHash hash: String, completion: @escaping (ApiServiceResult<Web3EthTransaction>) -> Void) {
		DispatchQueue.global().async {
			let result = self.web3.eth.getTransactionDetails(hash)
			switch result {
			case .success(let transaction):
				if let number = transaction.blockNumber {
					let resultBlockNumber = self.web3.eth.getBlockNumber()
					guard case .success(let blockNumber) = resultBlockNumber else {
						DispatchQueue.main.async {
							completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: nil, lastBlockNumber: nil)))
						}
						return
					}
					
					let result = self.web3.eth.getBlockByNumber(number)
					guard case .success(let block) = result else {
						DispatchQueue.main.async {
							completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: nil, lastBlockNumber: blockNumber)))
						}
						return
					}
					DispatchQueue.main.async {
						completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: block, lastBlockNumber: blockNumber)))
					}
				} else {
					DispatchQueue.main.async {
						completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: nil, lastBlockNumber: nil)))
					}
				}
				break
			case .failure(let error):
				DispatchQueue.main.async {
					completion(.failure(.internalError(message: "ETH Wallet: fail to load transaction details", error: error)))
				}
				break
			}
		}
	}
}
