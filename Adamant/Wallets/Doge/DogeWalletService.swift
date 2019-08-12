//
//  DogeWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import Swinject
import Alamofire
import BitcoinKit
import BitcoinKit.Private

struct DogeApiCommands {
    static func balance(for address: String) -> String {
        return "/addr/\(address)/balance"
    }
    
    static func getTransactions(for address: String) -> String {
        return "/addrs/\(address)/txs"
    }
    
    static func getTransaction(by hash: String) -> String {
        return "/tx/\(hash)"
    }
    
    static func getBlock(by hash: String) -> String {
        return "/block/\(hash)"
    }
    
    static func getUnspentTransactions(for address: String) -> String {
        return "/addr/\(address)/utxo"
    }
    
    static func sendTransaction() -> String {
        return "/tx/send"
    }
}

class DogeWalletService: WalletService {
    var wallet: WalletAccount? { return dogeWallet }
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Doge.wallet) as? DogeWalletViewController else {
            fatalError("Can't get DogeWalletViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "doge_transaction"
    let cellIdentifierSent = "dogeTransferSent"
    let cellIdentifierReceived = "dogeTransferReceived"
    let cellSource: CellSource? = CellSource.nib(nib: UINib(nibName: "TransferCollectionViewCell", bundle: nil))
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Constants
    static var currencySymbol = "DOGE"
    static var currencyLogo = #imageLiteral(resourceName: "wallet_doge")
    static let currencyExponent = -8
    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)
    static let chunkSize = 20
    
    private (set) var transactionFee: Decimal = 1.0 // 1 DOGE per transaction
    
    static let kvsAddress = "doge:address"
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.dogeWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.dogeWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.dogeWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.dogeWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol? = nil
    
    // MARK: - Properties
    private (set) var dogeWallet: DogeWallet? = nil
    
    private (set) var enabled = true
    
    public var network: Network
    
    private var initialBalanceCheck = false
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.dogeWalletService", qos: .utility, attributes: [.concurrent])
    let stateSemaphore = DispatchSemaphore(value: 1)
    
    private static let jsonDecoder = JSONDecoder()
    
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
        self.network = DogeMainnet()
        
        self.setState(.notInitiated)
        
        // MARK: Notifications
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
            self?.update()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
            self?.dogeWallet = nil
            self?.initialBalanceCheck = false
            if let balanceObserver = self?.balanceObserver {
                NotificationCenter.default.removeObserver(balanceObserver)
                self?.balanceObserver = nil
            }
        }
    }
    
    func update() {
        guard let wallet = dogeWallet else {
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
                switch error {
                case .networkError:
                    break
                    
                case .remoteServiceError(let message) where message.contains("Server not yet ready"):
                    break
                    
                default:
                    self?.dialogService.showRichError(error: error)
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
extension DogeWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        stateSemaphore.wait()
        setState(.initiationFailed(reason: reason))
        dogeWallet = nil
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
            
            let eWallet = DogeWallet(privateKey: privateKey)
            self.dogeWallet = eWallet
            
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
                    // DOGE already saved
                    if address != eWallet.address {
                        service.save(dogeAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
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
                        if let wallet = service.dogeWallet {
                            NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                        }
                        
                        service.save(dogeAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
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
extension DogeWalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
    }
}

// MARK: - Balances & addresses
extension DogeWalletService {
    func getBalance(_ completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        guard let url = AdamantResources.dogeServers.randomElement() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        guard let address = self.dogeWallet?.address else {
            completion(.failure(error: .walletNotInitiated))
            return
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.balance(for: address))
        
        // MARK: Sending request
        Alamofire.request(endpoint, method: .get, headers: headers).responseString(queue: defaultDispatchQueue) { response in
            
            switch response.result {
            case .success(let data):
                if let raw = Decimal(string: data) {
                    let balance = raw / DogeWalletService.multiplier
                    completion(.success(result: balance))
                } else {
                    completion(.failure(error: .remoteServiceError(message: "DOGE Wallet: \(data)")))
                }
                
            case .failure:
                completion(.failure(error: .networkError))
            }
        }
    }
    
    func getDogeAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        apiService.get(key: DogeWalletService.kvsAddress, sender: address, completion: completion)
    }
    
    func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void) {
        apiService.get(key: DogeWalletService.kvsAddress, sender: address) { (result) in
            switch result {
            case .success(let value):
                if let address = value {
                    completion(.success(result: address))
                } else {
                    completion(.failure(error: .walletNotInitiated))
                }
                
            case .failure(let error):
                completion(.failure(error: .internalError(message: "DOGE Wallet: fail to get address from KVS", error: error)))
            }
        }
    }
}

// MARK: - KVS
extension DogeWalletService {
    /// - Parameters:
    ///   - dogeAddress: DOGE address to save into KVS
    ///   - adamantAddress: Owner of Doge address
    ///   - completion: success
    private func save(dogeAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(error: .notLogged))
            return
        }
        
        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughMoney))
            return
        }
        
        apiService.store(key: DogeWalletService.kvsAddress, value: dogeAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
            switch result {
            case .success:
                completion(.success)
                
            case .failure(let error):
                completion(.failure(error: .apiError(error)))
            }
        }
    }
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(dogeAddress: String, result: WalletServiceSimpleResult) {
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
                    
                    self?.save(dogeAddress: dogeAddress) { result in
                        self?.kvsSaveCompletionRecursion(dogeAddress: dogeAddress, result: result)
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

// MARK: - Transactions
extension DogeWalletService {
    func getTransactions(from: Int, completion: @escaping (ApiServiceResult<(transactions: [DogeTransaction], hasMore: Bool)>) -> Void) {
        guard let address = self.wallet?.address else {
            completion(.failure(.notLogged))
            return
        }
        
        getTransactions(for: address, from: from, to: from + DogeWalletService.chunkSize) { response in
            switch response {
            case .success(let doge):
                let hasMore = doge.to < doge.totalItems
                
                let transactions = doge.items.map { $0.asBtcTransaction(DogeTransaction.self, for: address) }
                
                completion(.success((transactions: transactions, hasMore: hasMore)))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getTransactions(for address: String, from: Int, to: Int, completion: @escaping (ApiServiceResult<DogeGetTransactionsResponse>) -> Void) {
        guard let url = AdamantResources.dogeServers.randomElement() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        let parameters = [
            "from": from,
            "to": to
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.getTransactions(for: address))
        
        // MARK: Sending request
        Alamofire.request(endpoint, method: .get, parameters: parameters, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let dogeResponse = try DogeWalletService.jsonDecoder.decode(DogeGetTransactionsResponse.self, from: data)
                    completion(.success(dogeResponse))
                } catch {
                    completion(.failure(.internalError(message: "DOGE Wallet: not a valid response", error: error)))
                }
                
            case .failure(let error as URLError):
                completion(.failure(.networkError(error: error)))
                
            case .failure(let error):
                completion(.failure(.serverError(error: error.localizedDescription)))
            }
        }
    }
    
    func getUnspentTransactions(_ completion: @escaping (ApiServiceResult<[UnspentTransaction]>) -> Void) {
        guard let url = AdamantResources.dogeServers.randomElement() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        guard let wallet = self.dogeWallet else {
            completion(.failure(.notLogged))
            return
        }
        
        let address = wallet.address
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.getUnspentTransactions(for: address))
        
        let parameters = [
            "noCache": "1"
        ]
        
        // MARK: Sending request
        Alamofire.request(endpoint, method: .get, parameters: parameters, headers: headers).responseJSON(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                guard let items = data as? [[String: Any]] else {
                    completion(.failure(.internalError(message: "DOGE Wallet: not valid response", error: nil)))
                    break
                }
                
                var utxos = [UnspentTransaction]()
                for item in items {
                    guard let txid = item["txid"] as? String,
                        let vout = item["vout"] as? NSNumber,
                        let amount = item["amount"] as? NSNumber else {
                        continue
                    }
                        
                    let value = NSDecimalNumber(decimal: (amount.decimalValue * DogeWalletService.multiplier)).uint64Value
                    
                    let lockScript = Script.buildPublicKeyHashOut(pubKeyHash: wallet.publicKey.toCashaddr().data)
                    let txHash = Data(hex: txid).map { Data($0.reversed()) } ?? Data()
                    let txIndex = vout.uint32Value
                    
                    let unspentOutput = TransactionOutput(value: value, lockingScript: lockScript)
                    let unspentOutpoint = TransactionOutPoint(hash: txHash, index: txIndex)
                    let utxo = UnspentTransaction(output: unspentOutput, outpoint: unspentOutpoint)
                    
                    utxos.append(utxo)
                }
                
                completion(.success(utxos))
                
            case .failure:
                completion(.failure(.internalError(message: "DOGE Wallet: server not response", error: nil)))
            }
        }
    }
    
    func getTransaction(by hash: String, completion: @escaping (ApiServiceResult<BTCRawTransaction>) -> Void) {
        guard let url = AdamantResources.dogeServers.randomElement() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.getTransaction(by: hash))
        
        // MARK: Sending request
        Alamofire.request(endpoint, method: .get, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let transfers = try DogeWalletService.jsonDecoder.decode(BTCRawTransaction.self, from: data)
                    completion(.success(transfers))
                } catch {
                    completion(.failure(.internalError(message: "Unaviable transaction", error: error)))
                }
                
            case .failure(let error):
                completion(.failure(.internalError(message: "Unaviable transaction", error: error)))
            }
        }
    }
    
    func getBlockId(by hash: String, completion: @escaping (ApiServiceResult<String>) -> Void) {
        guard let url = AdamantResources.dogeServers.randomElement() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.getBlock(by: hash))
        Alamofire.request(endpoint, method: .get, headers: headers).responseJSON(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let json as [String: Any]):
                if let height = json["height"] as? NSNumber {
                    completion(.success(height.stringValue))
                } else {
                    completion(.failure(.internalError(message: "Failed to parse block", error: nil)))
                }
                
            case .failure(let error):
                completion(.failure(.internalError(message: "No block", error: error)))
                
            default:
                completion(.failure(.internalError(message: "No block", error: nil)))
            }
        }
    }
}

// MARK: - WalletServiceWithTransfers
extension DogeWalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Doge.transactionsList) as? DogeTransactionsViewController else {
            fatalError("Can't get DogeTransactionsViewController")
        }
        
        vc.walletService = self
        return vc
    }
}

// MARK: - PrivateKey generator
extension DogeWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Doge"
    }
    
    var rowImage: UIImage? {
        return #imageLiteral(resourceName: "wallet_doge_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let privateKeyData = passphrase.data(using: .utf8)?.sha256() else {
            return nil
        }
            
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        return privateKey.toWIF()
    }
}
