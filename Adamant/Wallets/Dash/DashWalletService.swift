//
//  DashWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Swinject
import Alamofire
import BitcoinKit

class DashWalletService: WalletService {
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenName: String {
        return ""
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
    
    var tokenNetworkSymbol: String {
        return "DASH"
    }
    
    var consistencyMaxTime: Double {
        return 800
    }
   
    var wallet: WalletAccount? { return dashWallet }
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Dash.wallet) as? DashWalletViewController else {
            fatalError("Can't get DashWalletViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "dash_transaction"
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var securedStore: SecuredStore!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Constants
    static var currencySymbol = "DASH"
    static var currencyLogo = #imageLiteral(resourceName: "wallet_dash")
    
    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)
    static let chunkSize = 20
    
    private (set) var transactionFee: Decimal = 0.0001 // 0.0001 DASH per transaction
    
    static let kvsAddress = "dash:address"
    
    internal var transatrionsIds = [String]()
    
    internal var lastTransactionId: String? {
        get {
            guard
                let hash: String = self.securedStore.get("lastDashTransactionId"),
                let timestampString: String = self.securedStore.get("lastDashTransactionTime"),
                let timestamp = Double(string: timestampString)
            else { return nil }
            
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let timeAgo = -1 * date.timeIntervalSinceNow
            
            if timeAgo > 10 * 60 { // 10m waiting for transaction complete
                self.securedStore.remove("lastDashTransactionTime")
                self.securedStore.remove("lastDashTransactionId")
                return nil
            } else {
                return hash
            }
        }
        set {
            if let value = newValue {
                let timestamp = Date().timeIntervalSince1970
                self.securedStore.set("\(timestamp)", for: "lastDashTransactionTime")
                self.securedStore.set(value, for: "lastDashTransactionId")
            } else {
                self.securedStore.remove("lastDashTransactionTime")
                self.securedStore.remove("lastDashTransactionId")
            }
        }
    }
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.dashWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.dashWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.dashWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.dashWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Properties
    private (set) var dashWallet: DashWallet?
    
    private (set) var enabled = true
    
    public var network: Network
    
    private var initialBalanceCheck = false
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.dashWalletService", qos: .userInteractive, attributes: [.concurrent])
    let stateSemaphore = DispatchSemaphore(value: 1)
    
    static let jsonDecoder = JSONDecoder()
    
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
    
    init() {
        self.network = DashMainnet()
        
        self.setState(.notInitiated)
    }
    
    func update() {
        guard let wallet = dashWallet else {
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
                switch error {
                case .networkError:
                    break
                    
                case .remoteServiceError(let message) where message.contains("Server not yet ready"):
                    break
                    
                default:
                    print("\(error.localizedDescription)")
                }
            }
            
            self?.setState(.upToDate)
        }
    }
    
    func validate(address: String) -> AddressValidationResult {
        return AddressFactory.isValid(bitcoinAddress: address) ? .valid : .invalid
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension DashWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        stateSemaphore.wait()
        setState(.initiationFailed(reason: reason))
        dashWallet = nil
        stateSemaphore.signal()
    }
    
    func initWallet(withPassphrase passphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void) {
        guard let adamant = accountService.account else {
            completion(.failure(error: .notLogged))
            return
        }
        
        stateSemaphore.wait()
        
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        defaultDispatchQueue.async { [unowned self] in
            let privateKeyData = passphrase.data(using: .utf8)!.sha256()
            let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
            
            let eWallet = DashWallet(privateKey: privateKey)
            self.dashWallet = eWallet
            
            if !self.enabled {
                self.enabled = true
                NotificationCenter.default.post(name: self.serviceEnabledChanged, object: self)
            }
            
            self.stateSemaphore.signal()
            
            // MARK: 4. Save address into KVS
            self.getWalletAddress(byAdamantAddress: adamant.address) { [weak self] result in
                guard let service = self else {
                    return
                }
                
                switch result {
                case .success(let address):
                    // Dash already saved
                    if address != eWallet.address {
                        service.save(dashAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(dashAddress: eWallet.address, result: result)
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
                        if let wallet = service.dashWallet {
                            NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                        }
                        
                        service.save(dashAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(dashAddress: eWallet.address, result: result)
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
    }
}

// MARK: - Dependencies
extension DashWalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        securedStore = container.resolve(SecuredStore.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
    }
}

// MARK: - Balances & addresses
extension DashWalletService {
    func getBalance(_ completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        guard let endpoint = AdamantResources.dashServers.randomElement() else {
            fatalError("Failed to get DASH endpoint URL")
        }

        guard let address = self.dashWallet?.address else {
            completion(.failure(error: .walletNotInitiated))
            return
        }

        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // Parameters
        let parameters: Parameters = [
            "method": "getaddressbalance",
            "params": [
                address
            ]
        ]
        
        // MARK: Sending request
        AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: defaultDispatchQueue) { response in

            switch response.result {
            case .success(let data):
                if let object = data as? [String: Any] {
                    let result = object["result"] as? [String: Any]
                    let error = object["error"]
                    
                    if error is NSNull, let result = result, let raw = result["balance"] as? Int64 {
                        let balance = Decimal(raw) / DashWalletService.multiplier
                        completion(.success(result: balance))
                    } else {
                        completion(.failure(error: .remoteServiceError(message: "DASH Wallet: \(data)")))
                    }
                } else {
                    completion(.failure(error: .remoteServiceError(message: "DASH Wallet: \(data)")))
                }

            case .failure:
                completion(.failure(error: .networkError))
            }
        }
    }

    func getDashAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        apiService.get(key: DashWalletService.kvsAddress, sender: address, completion: completion)
    }
    
    func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void) {
        apiService.get(key: DashWalletService.kvsAddress, sender: address) { (result) in
            switch result {
            case .success(let value):
                if let address = value {
                    completion(.success(result: address))
                } else {
                    completion(.failure(error: .walletNotInitiated))
                }

            case .failure(let error):
                completion(.failure(error: .internalError(message: "DASH Wallet: fail to get address from KVS", error: error)))
            }
        }
    }
}

// MARK: - KVS
extension DashWalletService {
    /// - Parameters:
    ///   - dashAddress: DASH address to save into KVS
    ///   - adamantAddress: Owner of Dash address
    ///   - completion: success
    private func save(dashAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(error: .notLogged))
            return
        }

        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughMoney))
            return
        }

        apiService.store(key: DashWalletService.kvsAddress, value: dashAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
            switch result {
            case .success:
                completion(.success)

            case .failure(let error):
                completion(.failure(error: .apiError(error)))
            }
        }
    }
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(dashAddress: String, result: WalletServiceSimpleResult) {
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

                    self?.save(dashAddress: dashAddress) { result in
                        self?.kvsSaveCompletionRecursion(dashAddress: dashAddress, result: result)
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

// MARK: - WalletServiceWithTransfers
extension DashWalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Dash.transactionsList) as? DashTransactionsViewController else {
            fatalError("Can't get DashTransactionsViewController")
        }

        vc.walletService = self
        return vc
    }
}

// MARK: - PrivateKey generator
extension DashWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Dash"
    }
    
    var rowImage: UIImage? {
        return #imageLiteral(resourceName: "wallet_dash_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let privateKeyData = passphrase.data(using: .utf8)?.sha256() else {
            return nil
        }
        
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        return privateKey.toWIF()
    }
}
