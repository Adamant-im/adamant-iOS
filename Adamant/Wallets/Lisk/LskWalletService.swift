//
//  LskWalletService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import BigInt
import Lisk
import Ed25519
import web3swift

class LskWalletService: WalletService {
    
    var wallet: WalletAccount? { return lskWallet }
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Lisk.wallet) as? LskWalletViewController else {
            fatalError("Can't get LskWalletViewController")
        }
        
        vc.service = self
        return vc
    }
	
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.lskhWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.lskWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.lskWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.lskWallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "lsk_transaction"
    let cellIdentifierSent = "lskTransferSent"
    let cellIdentifierReceived = "lskTransferReceived"
    let cellSource: CellSource? = CellSource.nib(nib: UINib(nibName: "TransferCollectionViewCell", bundle: nil))
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
	
	// MARK: - Constants
	let addressRegex = try! NSRegularExpression(pattern: "^([0-9]{2,22})L$", options: [])
    let maxAddressNumber = BigUInt("18446744073709551615")!
	let transactionFee: Decimal = 0.1
	private (set) var enabled = true
	
	static var currencySymbol = "LSK"
	static var currencyLogo = #imageLiteral(resourceName: "wallet_lsk")
    static let currencyExponent = -8
    
    static let kvsAddress = "lsk:address"
    static let defaultFee = 0.1
	
	
	// MARK: - Properties
	let transferAvailable: Bool = true
    private var initialBalanceCheck = false
    
    internal var accountApi: Accounts!
    internal var transactionApi: Transactions!
    
    private (set) var lskWallet: LskWallet? = nil
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.lskWalletService", qos: .utility, attributes: [.concurrent])
	
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
    
    let stateSemaphore = DispatchSemaphore(value: 1)
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol? = nil
	
	
	// MARK: - Logic
    init() {
        accountApi = Accounts(client: .testnet)
        transactionApi = Transactions(client: .testnet)
        
        // Notifications
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.lskWallet = nil
            self?.initialBalanceCheck = false
            if let balanceObserver = self?.balanceObserver {
                NotificationCenter.default.removeObserver(balanceObserver)
                self?.balanceObserver = nil
            }
        }
    }
    
	func update() {
        guard let wallet = lskWallet else {
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
        
        getBalance { [weak self] result in
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
                self?.dialogService.showRichError(error: error)
            }
            
            self?.setState(.upToDate)
        }
	}
	
	
	// MARK: - Tools
	func validate(address: String) -> AddressValidationResult {
        let full: String
        let short: String
        
        guard let last = address.last else {
            return .invalid
        }
        
        if last == "L" {
            full = address
            short = address.replacingOccurrences(of: "L", with: "")
        } else {
            full = "\(address)L"
            short = address
        }
        
        if addressRegex.perfectMatch(with: full), let number = BigUInt(short), number < maxAddressNumber {
            return .valid
        } else {
            return .invalid
        }
	}
    
    func fromRawLsk(value: BigUInt) -> String {
        if let formattedAmount = Web3.Utils.formatToPrecision(value, numberDecimals: 8, formattingDecimals: 8, decimalSeparator: ".", fallbackToScientific: false) {
            return formattedAmount
        } else {
            return "--"
        }
    }
    
    func toRawLsk(value: Double) -> String {
        if let formattedAmount = Web3.Utils.parseToBigUInt("\(value)", decimals: 8) {
            return "\(formattedAmount)"
        } else {
            return "--"
        }
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension LskWalletService: InitiatedWithPassphraseService {
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
        do {
            let keyPair = try Lisk.Crypto.keyPair(fromPassphrase: passphrase, salt: "adm")
            let address = Lisk.Crypto.address(fromPublicKey: keyPair.publicKeyString)
            
            // MARK: 3. Update
            let wallet = LskWallet(address: address, keyPair: keyPair)
            self.lskWallet = wallet
        } catch {
            print("\(error)")
            completion(.failure(error: .accountNotFound))
            stateSemaphore.signal()
            return
        }
        
        if !enabled {
            enabled = true
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        stateSemaphore.signal()
        
        guard let eWallet = self.lskWallet else {
            completion(.failure(error: .accountNotFound))
            return
        }
        
        // MARK: 4. Save into KVS
        getWalletAddress(byAdamantAddress: adamant.address) { [weak self] result in
            guard let service = self else {
                return
            }
            
            switch result {
            case .success(let address):
                // LSK already saved
                if address != eWallet.address {
                    service.save(lskAddress: eWallet.address) { result in
                        service.kvsSaveCompletionRecursion(lskAddress: eWallet.address, result: result)
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
                    if let wallet = service.lskWallet {
                        NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                    }
                    
                    service.save(lskAddress: eWallet.address) { result in
                        service.kvsSaveCompletionRecursion(lskAddress: eWallet.address, result: result)
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
        lskWallet = nil
        stateSemaphore.signal()
    }
    
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(lskAddress: String, result: WalletServiceSimpleResult) {
        if let observer = balanceObserver {
            NotificationCenter.default.removeObserver(observer)
            balanceObserver = nil
        }
        
        switch result {
        case .success:
            break
            
        case .failure(let error):
            switch error {
            case .notEnoughtMoney:  // Possibly new account, we need to wait for dropship
                // Register observer
                let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
                    guard let balance = self?.accountService.account?.balance, balance > AdamantApiService.KvsFee else {
                        return
                    }
                    
                    self?.save(lskAddress: lskAddress) { result in
                        self?.kvsSaveCompletionRecursion(lskAddress: lskAddress, result: result)
                    }
                }
                
                // Save referense to unregister it later
                balanceObserver = observer
                
            default:
                dialogService.showRichError(error: error)
            }
        }
    }
}

// MARK: - Dependencies
extension LskWalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
    }
}

// MARK: - Balances & addresses
extension LskWalletService {
    func getBalance(_ completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        if let address = self.lskWallet?.address {
            accountApi.accounts(address: address) { (response) in
                switch response {
                case .success(response: let response):
                    if let account = response.data.first {
                        let balance = BigUInt(account.balance ?? "0") ?? BigUInt(0)
                        
                        completion(.success(result: balance.asDecimal(exponent: LskWalletService.currencyExponent)))
                    } else {
                        completion(.success(result: 0))
                    }
                    
                    break
                case .error(response: let error):
                    print(error)
                    
                    completion(.failure(error: .internalError(message: error.message, error: nil)))
                    break
                }
            }
        } else {
            completion(.failure(error: .internalError(message: "LSK Wallet: not found", error: nil)))
        }
    }
    
    func getLskAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        apiService.get(key: AdamantLskApiService.kvsAddress, sender: address, completion: completion)
    }
    
    func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void) {
        apiService.get(key: LskWalletService.kvsAddress, sender: address) { (result) in
            switch result {
            case .success(let value):
                if let address = value {
                    completion(.success(result: address))
                } else {
                    completion(.failure(error: .walletNotInitiated))
                }

            case .failure(let error):
                completion(.failure(error: .internalError(message: "LSK Wallet: fail to get address from KVS", error: error)))
            }
        }
    }
}


// MARK: - KVS
extension LskWalletService {
    /// - Parameters:
    ///   - lskAddress: Lisk address to save into KVS
    ///   - adamantAddress: Owner of Lisk address
    ///   - completion: success
    private func save(lskAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(error: .notLogged))
            return
        }
        
        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughtMoney))
            return
        }
        
        apiService.store(key: LskWalletService.kvsAddress, value: lskAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
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
extension LskWalletService {
    func getTransactions(_ completion: @escaping (ApiServiceResult<[Transactions.TransactionModel]>) -> Void) {
        if let address = self.wallet?.address {
            transactionApi.transactions(senderIdOrRecipientId: address, limit: 100, offset: 0, sort: APIRequest.Sort("timestamp", direction: .descending)) { (response) in
                switch response {
                case .success(response: let result):
                    completion(.success(result.data))
                    break
                case .error(response: let error):
                    print("ERROR: " + error.message)
                    completion(.failure(.internalError(message: error.message, error: nil)))
                    break
                }
            }
        }
    }
    
    func getTransaction(by hash: String, completion: @escaping (ApiServiceResult<Transactions.TransactionModel>) -> Void) {
        transactionApi.transactions(id: hash, limit: 1, offset: 0) { (response) in
            switch response {
            case .success(response: let result):
                if let transaction = result.data.first {
                    completion(.success(transaction))
                } else {
                    completion(.failure(.internalError(message: "No transaction", error: nil)))
                }
                break
            case .error(response: let error):
                print("ERROR: " + error.message)
                completion(.failure(.internalError(message: error.message, error: nil)))
                break
            }
        }
    }
}
