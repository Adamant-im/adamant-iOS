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
import BigInt
import Swinject

class EthWalletService: WalletService {
	// MARK: - Constants
	let transactionFee: Decimal = 0.0
	
	static var currencySymbol = "ETH"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_eth")
	
	
	// MARK: - Dependencies
	weak var accountService: AccountService!
	var apiService: ApiService!
	var dialogService: DialogService!
	var router: Router!
	
	var web3: web3!
	
	// MARK: - Notifications
	let walletUpdatedNotification = Notification.Name("adamant.ethWalletService.walletUpdated")
	let serviceEnabledChanged = Notification.Name("adamant.ethWalletService.enabledChanged")
	
	// MARK: - Properties
	private (set) var enabled = true
	
	let stateSemaphore = DispatchSemaphore(value: 1)
	
	var walletViewController: WalletViewController {
		guard let vc = router.get(scene: AdamantScene.Wallets.EthereumWallet) as? EthWalletViewController else {
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
	init() {
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
			switch result {
			case .success(let balance):
				if wallet.balance != balance {
					defer { self.stateSemaphore.signal() }
					self.stateSemaphore.wait()
					
					wallet.balance = balance
					NotificationCenter.default.post(name: self.walletUpdatedNotification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
				}
				
			case .failure(let error):
				self.dialogService.showRichError(error: error)
			}
		}
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
		
		guard let ethAddress = keystore.addresses?.first else {
			completion(.failure(error: .internalError(message: "ETH Wallet: failed to create Keystore", error: nil)))
			stateSemaphore.signal()
			return
		}
		
		// MARK: 3. Update
		ethWallet = EthWallet(address: ethAddress.address, ethAddress: ethAddress)
		state = .initiated
		
		if !enabled {
			enabled = true
			NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
		}
		
		// MARK: 4. Save into KVS
		save(ethAddress: ethAddress.address) { [weak self] result in
			switch result {
			case .success:
				break
				
			case .failure(let error):
				self?.dialogService.showRichError(error: error)
			}
		}
		
		stateSemaphore.signal()
		
		// MARK: 5. Initiate update
		update()
	}
}


extension EthWalletService: WalletWithTransfers {
	func transferListViewController() -> UIViewController {
		fatalError()
	}
}

extension EthWalletService: WalletWithSend {
	func showTransfer(recipient: String?) {
		print("Transfer money to \(recipient ?? "nil")")
	}
}


// MARK: - Tools
extension EthWalletService {
	func validate(address: String) -> AddressValidationResult {
		return .valid
	}
	
	func getBalance(forAddress address: EthereumAddress, completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
		DispatchQueue.global(qos: .utility).async { [weak self] in
			guard let web3 = self?.web3 else {
				print("Can't get web3 service")
				return
			}
			
			let result = web3.eth.getBalance(address: address)
			
			switch result {
			case .success(let balance):
				completion(.success(result: balance.asDecimal()))
				
			case .failure(let error):
				switch error {
				case .connectionError:
					completion(.failure(error: .networkError))
					
				case .nodeError(let message):
					completion(.failure(error: .remoteServiceError(message: message)))
					
				case .generalError(let error),
					 .keystoreError(let error as Error):
					completion(.failure(error: .internalError(message: error.localizedDescription, error: error)))
					
				case .inputError(let message):
					completion(.failure(error: .internalError(message: message, error: nil)))
					
				case .transactionSerializationError,
					 .dataError,
					 .walletError,
					 .unknownError:
					completion(.failure(error: .internalError(message: "Unknown error", error: nil)))
				}
			}
		}
	}
	
	func getEthAddress(byAdamandAddress address: String, completion: @escaping (WalletServiceResult<String?>) -> Void) {
		apiService.get(key: AdamantEthApiService.kvsAddress, sender: address) { (result) in
			switch result {
			case .success(let value):
				completion(.success(result: value))
				
			case .failure(let error):
				completion(.failure(error: .internalError(message: "ETH Wallet: fail to get address from KVS", error: error)))
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
		
		getEthAddress(byAdamandAddress: adamant.address) { result in
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
				
				api?.store(key: AdamantEthApiService.kvsAddress, value: ethAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
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
