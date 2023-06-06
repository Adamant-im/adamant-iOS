//
//  DogeWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Swinject
import Alamofire
import BitcoinKit
import Combine

struct DogeApiCommands {
    static func balance(for address: String) -> String {
        return "/api/addr/\(address)/balance"
    }
    
    static func getTransactions(for address: String) -> String {
        return "/api/addrs/\(address)/txs"
    }
    
    static func getTransaction(by hash: String) -> String {
        return "/api/tx/\(hash)"
    }
    
    static func getBlock(by hash: String) -> String {
        return "/api/block/\(hash)"
    }
    
    static func getUnspentTransactions(for address: String) -> String {
        return "/api/addr/\(address)/utxo"
    }
    
    static func sendTransaction() -> String {
        return "/api/tx/send"
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
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    var addressConverter: AddressConverter!
    
    // MARK: - Constants
    static var currencyLogo = #imageLiteral(resourceName: "doge_wallet")
    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)
    static let chunkSize = 20
 
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
    
    var tokenNetworkSymbol: String {
        return "DOGE"
    }
   
    var tokenContract: String {
        return ""
    }
    
    var tokenUnicID: String {
        return tokenNetworkSymbol + tokenSymbol
    }
    
    var transactionFee: Decimal {
        return DogeWalletService.fixedFee
    }
    
    var richMessageType: String {
        return Self.richMessageType
	}

    var qqPrefix: String {
        return Self.qqPrefix
    }
    
    static let kvsAddress = "doge:address"
    
    private (set) var isWarningGasPrice = false
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.dogeWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.dogeWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.dogeWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.dogeWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Properties
    private (set) var dogeWallet: DogeWallet?
    
    private (set) var enabled = true
    
    public var network: Network
    
    private var initialBalanceCheck = false
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.dogeWalletService", qos: .userInteractive, attributes: [.concurrent])
    
    private static let jsonDecoder = JSONDecoder()
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
        self.network = DogeMainnet()
        
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
                self?.dogeWallet = nil
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
            await update()
        }
    }
    
    func update() async {
        guard let wallet = dogeWallet else {
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
                NotificationCenter.default.post(name: notification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
            }
        }
        
        setState(.upToDate)
    }
    
    func validate(address: String) -> AddressValidationResult {
        (try? addressConverter.convert(address: address)) != nil
            ? .valid
            : .invalid
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension DogeWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        dogeWallet = nil
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
        
        let eWallet = try DogeWallet(privateKey: privateKey, addressConverter: addressConverter)
        self.dogeWallet = eWallet
        
        if !self.enabled {
            self.enabled = true
            NotificationCenter.default.post(name: self.serviceEnabledChanged, object: self)
        }
        
        // MARK: 4. Save address into KVS
        let service = self
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            if address != eWallet.address {
                service.save(dogeAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
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
                if let wallet = service.dogeWallet {
                    wallet.isBalanceInitialized = true
                    NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                }
                
                service.save(dogeAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
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
extension DogeWalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
        addressConverter = container.resolve(AddressConverterFactory.self)?
            .make(network: network)
    }
}

// MARK: - Balances & addresses
extension DogeWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = dogeWallet?.address else {
            throw WalletServiceError.walletNotInitiated
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        guard let url = DogeWalletService.nodes.randomElement()?.asURL() else {
            let message = "Failed to get DOGE endpoint URL"
            assertionFailure(message)
            throw WalletServiceError.internalError(message: message, error: nil)
        }
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.balance(for: address))
        
        // MARK: Sending request
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Decimal, Error>) in
            AF.request(endpoint, method: .get, headers: headers).responseString { response in
                switch response.result {
                case .success(let data):
                    if let raw = Decimal(string: data) {
                        let balance = raw / DogeWalletService.multiplier
                        continuation.resume(returning: balance)
                    } else {
                        continuation.resume(throwing: WalletServiceError.remoteServiceError(message: "DOGE Wallet: \(data)"))
                    }
                    
                case .failure:
                    continuation.resume(throwing: WalletServiceError.networkError)
                }
            }
        }
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        do {
            let result = try await apiService.get(key: DogeWalletService.kvsAddress, sender: address)
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "DOGE Wallet: failed to get address from KVS"
            )
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
                print("\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Transactions
extension DogeWalletService {
    func getTransactions(from: Int) async throws -> (transactions: [DogeTransaction], hasMore: Bool) {
        guard let address = self.wallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        let doge = try await getTransactions(
            for: address,
            from: from,
            to: from + DogeWalletService.chunkSize
        )
        
        let hasMore = doge.to < doge.totalItems
        
        let transactions = doge.items.filter { !$0.isDoubleSpend }.map { $0.asBtcTransaction(DogeTransaction.self, for: address) }
        
        return (transactions: transactions, hasMore: hasMore)
    }
    
    private func getTransactions(for address: String, from: Int, to: Int) async throws -> DogeGetTransactionsResponse {
        guard let url = DogeWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        let parameters: Parameters = [
            "from": from,
            "to": to
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.getTransactions(for: address))
        
        // MARK: Sending request
        do {
            let dogeResponse: DogeGetTransactionsResponse = try await apiService.sendRequest(
                url: endpoint,
                method: .get,
                parameters: parameters
            )
            return dogeResponse
        } catch {
            throw WalletServiceError.remoteServiceError(message: "DOGE Wallet: not a valid response")
        }
    }
    
    func getUnspentTransactions() async throws -> [UnspentTransaction] {
        guard let url = DogeWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        guard let wallet = self.dogeWallet else {
            throw WalletServiceError.notLogged
        }
        
        let address = wallet.address
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.getUnspentTransactions(for: address))
        
        let parameters: Parameters = [
            "noCache": "1"
        ]
        
        // MARK: Sending request
        
        let data = try await apiService.sendRequest(
            url: endpoint,
            method: .get,
            parameters: parameters
        )

        let items = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [[String: Any]]

        guard let items = items else {
            throw WalletServiceError.remoteServiceError(
                message: "DOGE Wallet: not valid response"
            )
        }

        var utxos = [UnspentTransaction]()
        for item in items {
            guard
                let txid = item["txid"] as? String,
                let confirmations = item["confirmations"] as? NSNumber,
                confirmations.intValue > 0,
                let vout = item["vout"] as? NSNumber,
                let amount = item["amount"] as? NSNumber else {
                continue
            }

            let value = NSDecimalNumber(decimal: (amount.decimalValue * DogeWalletService.multiplier)).uint64Value
            
            let lockScript = wallet.addressEntity.lockingScript
            let txHash = Data(hex: txid).map { Data($0.reversed()) } ?? Data()
            let txIndex = vout.uint32Value

            let unspentOutput = TransactionOutput(value: value, lockingScript: lockScript)
            let unspentOutpoint = TransactionOutPoint(hash: txHash, index: txIndex)
            let utxo = UnspentTransaction(output: unspentOutput, outpoint: unspentOutpoint)

            utxos.append(utxo)
        }

        return utxos
    }
    
    func getTransaction(by hash: String) async throws -> BTCRawTransaction {
        guard let url = DogeWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        // Request url
        
        let endpoint = url.appendingPathComponent(DogeApiCommands.getTransaction(by: hash))
        
        // MARK: Sending request
        
        let transaction: BTCRawTransaction = try await apiService.sendRequest(
            url: endpoint,
            method: .get,
            parameters: nil
        )
        
        return transaction
    }
    
    func getBlockId(by hash: String) async throws -> String {
        guard let url = DogeWalletService.nodes.randomElement()?.asURL() else {
            fatalError("Failed to get DOGE endpoint URL")
        }
        
        // Request url
        
        let endpoint = url.appendingPathComponent(DogeApiCommands.getBlock(by: hash))

        let data = try await apiService.sendRequest(
            url: endpoint,
            method: .get,
            parameters: nil
        )
        
        let json = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: Any]
        
        guard let json = json else {
            throw WalletServiceError.remoteServiceError(
                message: "DOGE Wallet: not valid response"
            )
        }
        
        if let height = json["height"] as? NSNumber {
            return height.stringValue
        } else {
            throw WalletServiceError.remoteServiceError(message: "Failed to parse block")
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
        return #imageLiteral(resourceName: "doge_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let privateKeyData = passphrase.data(using: .utf8)?.sha256() else {
            return nil
        }
            
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        return privateKey.toWIF()
    }
}
