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
import Combine

enum DefaultBtcTransferFee: Decimal {
    case high = 24000
    case medium = 12000
    case low = 3000
}

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

    static func getTransactions(for address: String, fromTx: String? = nil) -> String {
        var url = "/address/\(address)/txs"
        if let fromTx = fromTx {
            url += "/chain/\(fromTx)"
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
        type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        type(of: self).currencyLogo
    }
    
    var tokenNetworkSymbol: String {
        "BTC"
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
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    var increaseFeeService: IncreaseFeeService!
    var addressConverter: AddressConverter!
    
    // MARK: - Constants
    static var currencyLogo = #imageLiteral(resourceName: "bitcoin_wallet")

    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)

    private (set) var currentHeight: Decimal?
    private var feeRate: Decimal = 1
    private (set) var transactionFee: Decimal = DefaultBtcTransferFee.medium.rawValue / multiplier
    private (set) var isWarningGasPrice = false
    
    static let kvsAddress = "btc:address"
    private let walletPath = "m/44'/0'/21'/0/0"
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.brchWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.btcWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.btcWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.btcWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Properties
    private (set) var btcWallet: BtcWallet?
    
    private (set) var enabled = true
    
    public var network: Network
    
    private var initialBalanceCheck = false
    
    static let jsonDecoder = JSONDecoder()
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.btcWalletService", qos: .userInteractive, attributes: [.concurrent])
    
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
    
    init() {
        self.network = BTCMainnet()
        self.setState(.notInitiated)
        
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
                self?.btcWallet = nil
                self?.initialBalanceCheck = false
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
            }
            .store(in: &subscriptions)
    }
    
    func update() {
        Task {
            try? await update()
        }
    }
    
    func update() async throws {
        guard let wallet = btcWallet else {
            return
        }
        
        switch state {
        case .notInitiated, .updating, .initiationFailed:
            return
            
        case .upToDate:
            break
        }
        
        setState(.updating)
        
        if let balance = try? await getBalance() {
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
                NotificationCenter.default.post(
                    name: notification,
                    object: self,
                    userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
                )
            }
        }
        
        setState(.upToDate)
        
        if let rate = try? await getFeeRate() {
            feeRate = rate
        }
        
        if let height = try? await getCurrentHeight() {
            currentHeight = height
        }
        
        if let transactions = try? await getUnspentTransactions() {
            let feeRate = feeRate
            
            let fee = Decimal(transactions.count * 181 + 78) * feeRate
            var newTransactionFee = fee / BtcWalletService.multiplier
            
            newTransactionFee = isIncreaseFeeEnabled
            ? newTransactionFee * defaultIncreaseFee
            : newTransactionFee
            
            guard transactionFee != newTransactionFee else { return }
            
            transactionFee = newTransactionFee
            
            NotificationCenter.default.post(name: transactionFeeUpdated, object: self, userInfo: nil)
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

            guard let charLoc = b58Chars.firstIndex(of: charAtIndex) else { continue }

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
        if isValid(bech32: address) {
            return true
        }

        guard address.count >= 26 && address.count <= 35,
              address.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil,
              let decodedAddress = getBase58DecodeAsBytes(address: address, length: 25),
              decodedAddress.count >= 4
        else {
            return false
        }

        let decodedAddressNoCheckSum = Array(decodedAddress.prefix(decodedAddress.count - 4))
        let hashedSum = decodedAddressNoCheckSum.sha256().sha256()

        let checkSum = Array(decodedAddress.suffix(from: decodedAddress.count - 4))
        let hashedSumHeader = Array(hashedSum.prefix(4))

        return hashedSumHeader == checkSum
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        do {
            let result = try await apiService.get(key: BtcWalletService.kvsAddress, sender: address)
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "BTC Wallet: failed to get address from KVS"
            )
        }
    }

    private func isValid(bech32 address: String) -> Bool {
        guard let decoded = try? SegwitAddrCoder().decode(hrp: "bc", addr: address) else {
            return false
        }

        do {
            let recoded = try SegwitAddrCoder().encode(
                hrp: "bc",
                version: decoded.version,
                program: decoded.program
            )
            return !recoded.isEmpty
        } catch {
            return false
        }
    }

}

// MARK: - WalletInitiatedWithPassphrase
extension BtcWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        btcWallet = nil
    }
    
    func initWallet(withPassphrase passphrase: String) async throws -> WalletAccount {
        guard let adamant = accountService.account else {
            throw WalletServiceError.notLogged
        }
        
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        let privateKeyData = passphrase.data(using: .utf8)!.sha256()
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        let eWallet = try BtcWallet(privateKey: privateKey, addressConverter: addressConverter)
        self.btcWallet = eWallet
        
        if !self.enabled {
            self.enabled = true
            NotificationCenter.default.post(name: self.serviceEnabledChanged, object: self)
        }
        
        // MARK: 4. Save address into KVS
        let service = self
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            if address != eWallet.address {
                service.save(btcAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(btcAddress: eWallet.address, result: result)
                }
                throw WalletServiceError.accountNotFound
            }
            
            service.initialBalanceCheck = true
            service.setState(.upToDate, silent: true)
            Task {
                service.update()
            }
            
            return eWallet
        } catch let error as WalletServiceError {
            switch error {
            case .walletNotInitiated:
                // Show '0' without waiting for balance update
                if let wallet = service.btcWallet {
                    wallet.isBalanceInitialized = true
                    NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                }
                
                service.save(btcAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(btcAddress: eWallet.address, result: result)
                }
                service.setState(.upToDate)
                return eWallet
                
            default:
                service.setState(.upToDate)
                throw error
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
        increaseFeeService = container.resolve(IncreaseFeeService.self)
        addressConverter = container.resolve(AddressConverterFactory.self)?.make(network: network)
    }
}

// MARK: - Balances & addresses
extension BtcWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = btcWallet?.address else {
            throw WalletServiceError.walletNotInitiated
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        guard let url = BtcWalletService.nodes.randomElement()?.asURL() else {
            let message = "Failed to get BTC endpoint URL"
            assertionFailure(message)
            throw WalletServiceError.internalError(message: message, error: nil)
        }
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.balance(for: address))
        
        // MARK: Sending request
        
        let response: BtcBalanceResponse = try await apiService.sendRequest(
            url: endpoint,
            method: .get,
            parameters: nil
        )
        
        let balance = response.value / BtcWalletService.multiplier
        
        return balance
    }

    func getFeeRate() async throws -> Decimal {
        guard let url = BtcWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.getFeeRate())
        
        // MARK: Sending request
        
        let response: [String: Decimal] = try await apiService.sendRequest(
            url: endpoint,
            method: .get,
            parameters: nil
        )
        
        let value = response["2"] ?? 1
        
        return value
    }

    func getCurrentHeight() async throws -> Decimal {
        guard let url = BtcWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.getHeight())
        
        // MARK: Sending request
        let data = try await apiService.sendRequest(
            url: endpoint,
            method: .get,
            parameters: nil
        )
        
        guard
            let raw = String(data: data, encoding: .utf8),
            let value = Decimal(string: raw)
        else {
            throw WalletServiceError.remoteServiceError(
                message: "BTC Wallet: not a valid response"
            )
        }
        
        return value
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
    func getTransactions(fromTx: String? = nil) async throws -> [BtcTransaction] {
        guard let address = self.wallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        let items = try await getTransactions(
            for: address,
            fromTx: fromTx
        )
        let transactions = items.map {
            $0.asBtcTransaction(
                BtcTransaction.self,
                for: address,
                height: self.currentHeight
            )
        }
        
        return transactions
    }

    private func getTransactions(for address: String, fromTx: String? = nil) async throws -> [RawBtcTransactionResponse] {
        guard let url = BtcWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.getTransactions(
            for: address,
            fromTx: fromTx
        ))
        
        // MARK: Sending request
        
        let transactions: [RawBtcTransactionResponse] = try await apiService.sendRequest(
            url: endpoint,
            method: .get,
            parameters: nil
        )
        
        return transactions
    }

    func getTransaction(by hash: String) async throws -> BtcTransaction {
        guard let address = self.wallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        guard let url = BtcWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.getTransaction(by: hash))
        
        // MARK: Sending request
        
        do {
            let rawTransaction: RawBtcTransactionResponse = try await apiService.sendRequest(
                url: endpoint,
                method: .get,
                parameters: nil
            )
            
            let transaction = rawTransaction.asBtcTransaction(
                BtcTransaction.self,
                for: address,
                height: self.currentHeight
            )
            
            return transaction
        } catch let error as ApiServiceError {
            throw WalletServiceError.remoteServiceError(message: error.message)
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

// MARK: - PrivateKey generator
extension BtcWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Bitcoin"
    }
    
    var rowImage: UIImage? {
        return #imageLiteral(resourceName: "bitcoin_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard
            AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase),
            let privateKeyData = passphrase.data(using: .utf8)?.sha256()
        else {
            return nil
        }

        let privateKey = PrivateKey(data: privateKeyData,
                                    network: self.network,
                                    isPublicKeyCompressed: true)
        return privateKey.toWIF()
    }
}

class BtcTransaction: BaseBtcTransaction {
    override class var defaultCurrencySymbol: String? { return BtcWalletService.currencySymbol }
}
