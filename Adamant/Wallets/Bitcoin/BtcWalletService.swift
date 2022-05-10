//
//  BtcWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Swinject
import Alamofire
import BitcoinKit
import BitcoinKitPrivate

struct BtcApiCommands {

    static func getHeight() -> String {
        return "/blocks/tip/height"
    }

    static func getFeeRate() -> String {
        return "/fee-estimates" //this._get('').then(estimates => estimates['2'])
    }

    static func balance(for address: String) -> String {
        return "/address/\(address)"
    }

    static func getTransactions(for address: String, toTx: String? = nil) -> String {
        var url = "/address/\(address)/txs"
        if let toTx = toTx {
            url += "/chain/\(toTx)"
        }
        return url
    }

    static func getTransaction(by hash: String) -> String {
        return "/tx/\(hash)"
    }
    
    static func getUnspentTransactions(for address: String) -> String {
        return "/address/\(address)/utxo"
    }
    
    static func sendTransaction() -> String {
        return "/tx"
    }
}

class BtcWalletService: WalletService {
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenName: String {
        return ""
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
    
    var wallet: WalletAccount? { return btcWallet }
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Bitcoin.wallet) as? BtcWalletViewController else {
            fatalError("Can't get BtcWalletViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "btc_transaction"
    let cellIdentifierSent = "btcTransferSent"
    let cellIdentifierReceived = "btcTransferReceived"
    let cellSource: CellSource? = CellSource.nib(nib: UINib(nibName: "TransferCollectionViewCell", bundle: nil))
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Constants
    static var currencySymbol = "BTC"
    static var currencyLogo = #imageLiteral(resourceName: "wallet_btc")

    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)

    static let defaultFee: Int64 = Priority.medium.rawValue
    
    enum Priority: Int64 {
        case high = 24000
        case medium = 12000
        case low = 3000
    }
    
    private (set) var transactionFee: Decimal = Decimal(BtcWalletService.defaultFee) / Decimal(100000000)
    
    static let kvsAddress = "btc:address"
    private let walletPath = "m/44'/0'/21'/0/0"
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.brchWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.btcWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.btcWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.btcWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol? = nil
    
    // MARK: - Properties
    private (set) var btcWallet: BtcWallet? = nil
    
    private (set) var enabled = true
    
    public var network: Network
    
    private var initialBalanceCheck = false
    
    private static let jsonDecoder = JSONDecoder()
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.btcWalletService", qos: .utility, attributes: [.concurrent])
    let stateSemaphore = DispatchSemaphore(value: 1)
    
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
    
    init(mainnet: Bool) {
        self.network = BTCMainnet()
        
        self.setState(.notInitiated)
    }
    
    func update() {
        guard let wallet = btcWallet else {
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
            self?.stateSemaphore.signal()
        }
    }
    
    func validate(address: String) -> AddressValidationResult {
        return isValid(bitcoinAddress: address) ? .valid : .invalid
    }

    private func getBase58DecodeAsBytes(address: String, length: Int) -> [UTF8.CodeUnit]? {
        let b58Chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

        var output: [UTF8.CodeUnit] = Array(repeating: 0, count: length)

        for i in 0..<address.count {
            let index = address.index(address.startIndex, offsetBy: i)
            let charAtIndex = address[index]

            guard let charLoc = b58Chars.index(of: charAtIndex) else { continue }

            var p = b58Chars.distance(from: b58Chars.startIndex, to: charLoc)
            for j in stride(from: length - 1, through: 0, by: -1) {
                p += 58 * Int(output[j] & 0xFF)
                output[j] = UTF8.CodeUnit(p % 256)

                p /= 256
            }

            guard p == 0 else { return nil }
        }

        return output
    }

    public func isValid(bitcoinAddress address: String) -> Bool {
        guard address.count >= 26 && address.count <= 35,
            address.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil,
            let decodedAddress = getBase58DecodeAsBytes(address: address, length: 25),
            decodedAddress.count >= 4
            else { return false }

        let decodedAddressNoCheckSum = Array(decodedAddress.prefix(decodedAddress.count - 4))
        let hashedSum = decodedAddressNoCheckSum.sha256().sha256()

        let checkSum = Array(decodedAddress.suffix(from: decodedAddress.count - 4))
        let hashedSumHeader = Array(hashedSum.prefix(4))

        return hashedSumHeader == checkSum
    }
    
    func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void) {
        apiService.get(key: BtcWalletService.kvsAddress, sender: address) { (result) in
            switch result {
            case .success(let value):
                if let address = value {
                    completion(.success(result: address))
                } else {
                    completion(.failure(error: .walletNotInitiated))
                }
                
            case .failure(let error):
                completion(.failure(error: .internalError(message: "BTC Wallet: fail to get address from KVS", error: error)))
            }
        }
    }

}
                        
// MARK: - WalletInitiatedWithPassphrase
extension BtcWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        stateSemaphore.wait()
        setState(.initiationFailed(reason: reason))
        btcWallet = nil
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
            let mnemonic = passphrase.components(separatedBy: " ")
            let seed = BitcoinKit.Mnemonic.seed(mnemonic: mnemonic)
            
            let keychain = HDKeychain(seed: seed, network: self.network)
            guard let privateKey = try? keychain.derivedKey(path: self.walletPath).privateKey() else {
                completion(.failure(error: .accountNotFound))
                self.stateSemaphore.signal()
                return
            }
            
            let eWallet = BtcWallet(privateKey: privateKey)
            self.btcWallet = eWallet
            
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
                    // BTC already saved
                    if address != eWallet.address {
                        service.save(btcAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(btcAddress: eWallet.address, result: result)
                        }
                        return
                    }

                    service.initialBalanceCheck = true
                    service.setState(.upToDate, silent: true)
                    service.update()
                    
                    completion(.success(result: eWallet))
                    
                case .failure(let error):
                    switch error {
                    case .walletNotInitiated:
                        // Show '0' without waiting for balance update
                        if let wallet = service.btcWallet {
                            NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                        }

                        service.save(btcAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(btcAddress: eWallet.address, result: result)
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
extension BtcWalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
    }
}

// MARK: - Balances & addresses
extension BtcWalletService {

    func getBalance(_ completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        guard let url = AdamantResources.btcServers.randomElement() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        guard let address = self.btcWallet?.address else {
            completion(.failure(error: .walletNotInitiated))
            return
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.balance(for: address))
        
        // MARK: Sending request
        AF.request(endpoint, method: .get, headers: headers).responseString(queue: defaultDispatchQueue) { response in
            
            switch response.result {
            case .success(let data):
                if let raw = Decimal(string: data) {
                    let balance = raw / BtcWalletService.multiplier
                    completion(.success(result: balance))
                } else {
                    completion(.failure(error: .remoteServiceError(message: "BTC Wallet: \(data)")))
                }
                
            case .failure:
                completion(.failure(error: .networkError))
            }
        }
    }

}

// MARK: - KVS
extension BtcWalletService {
    /// - Parameters:
    ///   - btcAddress: Bitcoin address to save into KVS
    ///   - adamantAddress: Owner of BTC address
    ///   - completion: success
    private func save(btcAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(error: .notLogged))
            return
        }
        
        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughMoney))
            return
        }
        
        apiService.store(key: BtcWalletService.kvsAddress, value: btcAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
            switch result {
            case .success:
                completion(.success)
                
            case .failure(let error):
                completion(.failure(error: .apiError(error)))
            }
        }
    }

    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(btcAddress: String, result: WalletServiceSimpleResult) {
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
                    
                    self?.save(btcAddress: btcAddress) { result in
                        self?.kvsSaveCompletionRecursion(btcAddress: btcAddress, result: result)
                    }
                }
                
                // Save referense to unregister it later
                balanceObserver = observer
                
            default:
                dialogService.showRichError(error: error)
            }
        }
    }
    
    private func kvsSaveCompletionRecursion(btcCheckpoint: Checkpoint, result: WalletServiceSimpleResult) {
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
extension BtcWalletService {
    func getTransactions(completion: @escaping (ApiServiceResult<[BtcTransaction]>) -> Void) {
        guard let address = self.wallet?.address else {
            completion(.failure(.notLogged))
            return
        }
        
        getTransactions(for: address) { response in
            switch response {
            case .success(let items):
                let transactions = items.map { $0.asBtcTransaction(BtcTransaction.self, for: address) }
                completion(.success(transactions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func getTransactions(for address: String, completion: @escaping (ApiServiceResult<[BTCRawTransaction]>) -> Void) {
        guard let url = AdamantResources.btcServers.randomElement() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.getTransactions(for: address))
        
        // MARK: Sending request
        AF.request(
            endpoint,
            method: .get,
            headers: headers
        ).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let response = try BtcWalletService.jsonDecoder.decode([BTCRawTransaction].self,
                                                                           from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(.internalError(message: "BTC Wallet: not a valid response",
                                                       error: error)))
                }
            case .failure(let error):
                completion(.failure(.serverError(error: error.localizedDescription)))
            }
        }
    }

    func getTransaction(by hash: String, completion: @escaping (ApiServiceResult<BtcTransaction>) -> Void) {
        guard let address = self.wallet?.address else {
            completion(.failure(.notLogged))
            return
        }

        guard let url = AdamantResources.dogeServers.randomElement() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.getTransaction(by: hash))
        
        // MARK: Sending request
        AF.request(
            endpoint,
            method: .get,
            headers: headers
        ).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                do {
                    let rawTransaction = try Self.jsonDecoder.decode(BTCRawTransaction.self,
                                                                     from: data)
                    let transaction = rawTransaction.asBtcTransaction(BtcTransaction.self,
                                                                      for: address)
                    completion(.success(transaction))
                } catch {
                    completion(.failure(.internalError(message: "Unaviable transaction", error: error)))
                }
                
            case .failure(let error):
                completion(.failure(.internalError(message: "No transaction", error: error)))
            }
        }
    }

}

extension BtcWalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Bitcoin.transactionsList) as? BtcTransactionsViewController else {
            fatalError("Can't get BtcTransactionsViewController")
        }
        
        vc.btcWalletService = self
        return vc
    }
}

class BtcTransaction: BaseBtcTransaction {
    override class var defaultCurrencySymbol: String? { return BtcWalletService.currencySymbol }
}
