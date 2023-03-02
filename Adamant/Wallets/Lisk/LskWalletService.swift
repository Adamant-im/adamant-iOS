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
import LiskKit
import web3swift
import Alamofire
import struct BigInt.BigUInt
import Web3Core

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
    let walletUpdatedNotification = Notification.Name("adamant.lskWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.lskWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.lskWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.lskWallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "lsk_transaction"
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Constants
    var transactionFee: Decimal {
        return transactionFeeRaw.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    var transactionFeeRaw: BigUInt = BigUInt(integerLiteral: 141000)
    private (set) var enabled = true
    
    static var currencyLogo = #imageLiteral(resourceName: "lisk_wallet")
    
    static let kvsAddress = "lsk:address"
    static let defaultFee: BigUInt = 141000
    
    var lastHeight: UInt64 = 0
    
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
	
    var tokenNetworkSymbol: String {
        return "LSK"
    }
    
    var tokenContract: String {
        return ""
    }
    
    var tokenUnicID: String {
        return tokenNetworkSymbol + tokenSymbol
    }
    
	// MARK: - Properties
	let transferAvailable: Bool = true
    private var initialBalanceCheck = false
    
    internal var accountApi: Accounts!
    internal var transactionApi: Transactions!
    internal var serviceApi: Service!
    internal var nodeApi: LiskKit.Node!
    internal var netHash: String = ""
    
    private (set) var lskWallet: LskWallet?
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.lskWalletService", qos: .utility, attributes: [.concurrent])
    
    private let mainnet: Bool
    private let nodes: [APINode]
    
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
        
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol?
    
    // MARK: - Logic
    convenience init(mainnet: Bool = true) {
        let nodes = mainnet ? APIOptions.mainnet.nodes : APIOptions.testnet.nodes
        let serviceNode = mainnet ? APIOptions.Service.mainnet.nodes : APIOptions.Service.testnet.nodes
        self.init(mainnet: mainnet, nodes: nodes, serviceNode: serviceNode)
    }
    
    convenience init(mainnet: Bool, nodes: [Node], services: [Node]) {
        self.init(mainnet: mainnet, nodes: nodes.map { APINode(origin: $0.asString()) }, serviceNode: services.map { APINode(origin: $0.asString()) })
    }
    
    init(mainnet: Bool, nodes: [APINode], serviceNode: [APINode]) {
        self.mainnet = mainnet
        self.nodes = nodes

        let client = APIClient(options: APIOptions(nodes: serviceNode, nethash: mainnet ? .mainnet : .testnet, randomNode: true))
        self.serviceApi = Service(client: client, version: .v2)

        setupApi()
        
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
        Task {
            await update()
        }
    }
    
    func update() async {
        guard let wallet = lskWallet else {
            return
        }
        
        switch state {
        case .notInitiated, .updating, .initiationFailed:
            return
            
        case .upToDate:
            break
        }
        
        setState(.updating)
        
        if let result = try? await getFees() {
            self.lastHeight = result.lastHeight
            self.transactionFeeRaw = result.fee > LskWalletService.defaultFee
            ? result.fee
            : LskWalletService.defaultFee
        }
        
        if let balance = try? await getBalance() {
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
    
    // MARK: - Tools
    func validate(address: String) -> AddressValidationResult {
        return validateAddress(address)
    }

    func validateAddress(_ address: String) -> AddressValidationResult {
        return LiskKit.Crypto.isValidBase32(address: address) ? .valid : .invalid
    }
    
    func fromRawLsk(value: BigInt.BigUInt) -> String {
        return Utilities.formatToPrecision(value, units: .custom(8), formattingDecimals: 8, decimalSeparator: ".", fallbackToScientific: false)
    }
    
    func toRawLsk(value: Double) -> String {
        if let formattedAmount = Utilities.parseToBigUInt("\(value)", decimals: 8) {
            return "\(formattedAmount)"
        } else {
            return "--"
        }
    }
    
    func getFees() async throws -> (fee: BigUInt, lastHeight: UInt64) {
        guard let wallet = lskWallet else {
            throw WalletServiceError.notLogged
        }
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<(fee: BigUInt, lastHeight: UInt64), Error>) in
            serviceApi.getFees { result in
                switch result {
                case .success(response: let value):
                    let tempTransaction = TransactionEntity(
                        amount: 100000000.0,
                        fee: 0.00141,
                        nonce: wallet.nounce,
                        senderPublicKey: wallet.keyPair.publicKeyString,
                        recipientAddress: wallet.binaryAddress
                    ).signed(
                        with: wallet.keyPair,
                        for: self.netHash
                    )
                    
                    let feeValue = tempTransaction.getFee(with: value.data.minFeePerByte)
                    let fee = BigUInt(feeValue)
                    
                    continuation.resume(returning: (fee: fee, lastHeight: value.meta.lastBlockHeight))
                case .error(response: let error):
                    continuation.resume(
                        throwing: WalletServiceError.internalError(
                            message: error.message,
                            error: nil
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Nodes
extension LskWalletService {
    private func initiateNodes(completion: @escaping (Bool) -> Void) {
        if nodes.count > 0 {
            netHash = Constants.Nethash.main
            let client = APIClient(options: APIOptions(nodes: nodes, nethash: APINethash.mainnet, randomNode: true))
            self.accountApi = Accounts(client: client)
            self.transactionApi = Transactions(client: client)
            self.nodeApi = LiskKit.Node(client: client)
            completion(true)
        } else {
            self.accountApi = nil
            self.transactionApi = nil
            self.nodeApi = nil
            self.serviceApi = nil
            completion(false)
        }
    }
    
    private func getAliveNodes(from nodes: [APINode], timeout: TimeInterval, completion: @escaping ([APINode]) -> Void) {
        let group = DispatchGroup()
        var aliveNodes = [APINode]()
        
        for node in nodes {
            if let url = URL(string: "\(node.origin)/api/node/status") {
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = timeout
                
                group.enter() // Enter 1
                
                AF.request(request).responseData { response in
                    defer { group.leave() } // Leave 1
                    
                    switch response.result {
                    case .success:
                        aliveNodes.append(node)
                        
                    case .failure:
                        break
                    }
                }
            }
        }
        
        group.notify(queue: defaultDispatchQueue) {
            completion(aliveNodes)
        }
    }
    
    func setupApi() {
        if mainnet {
            let group = DispatchGroup()
            group.enter()
            
            initiateNodes { _ in
                group.leave()
            }
            
            group.wait()
        } else {
            netHash = Constants.Nethash.test
            accountApi = Accounts(client: .testnet)
            transactionApi = Transactions(client: .testnet)
            nodeApi = LiskKit.Node(client: .testnet)
        }
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension LskWalletService: InitiatedWithPassphraseService {
    func initWallet(withPassphrase passphrase: String) async throws -> WalletAccount {
        guard let adamant = accountService.account else {
            throw WalletServiceError.notLogged
        }
        
        // MARK: 1. Prepare
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        // MARK: 2. Create keys and addresses
        do {
            let keyPair = try LiskKit.Crypto.keyPair(fromPassphrase: passphrase, salt: "adm")
            let address = LiskKit.Crypto.address(fromPublicKey: keyPair.publicKeyString)
         
            // MARK: 3. Update
            let wallet = LskWallet(address: address, keyPair: keyPair, nounce: "", isNewApi: true)
            self.lskWallet = wallet
        } catch {
            print("\(error)")
            throw WalletServiceError.accountNotFound
        }
        
        if !enabled {
            enabled = true
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        guard let eWallet = self.lskWallet else {
            throw WalletServiceError.accountNotFound
        }
        
        // MARK: 4. Save into KVS
        let service = self
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            
            if address != eWallet.address {
                service.save(lskAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(lskAddress: eWallet.address, result: result)
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
                if let wallet = service.lskWallet {
                    NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                }
                
                service.save(lskAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(lskAddress: eWallet.address, result: result)
                }
                service.setState(.upToDate)
                return eWallet
            default:
                service.setState(.upToDate)
                throw error
            }
        }
    }
    
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        lskWallet = nil
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
            case .notEnoughMoney:  // Possibly new account, we need to wait for dropship
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
                print("\(error.localizedDescription)")
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
    func getBalance() async throws -> Decimal {
        guard let wallet = self.lskWallet, let accountApi = accountApi else {
            throw WalletServiceError.notLogged
        }
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Decimal, Error>) in
            accountApi.accounts(address: wallet.binaryAddress) { response in
                switch response {
                case .success(response: let response):
                    self.lskWallet?.nounce = response.data.nonce
                    let balance = BigUInt(response.data.balance ?? "0") ?? BigUInt(0)
                    continuation.resume(
                        returning: balance.asDecimal(
                            exponent: LskWalletService.currencyExponent
                        )
                    )
                    
                case .error(response: let error):
                    if error.message == "Unexpected Error" {
                        continuation.resume(throwing: WalletServiceError.networkError)
                    } else {
                        continuation.resume(
                            throwing: WalletServiceError.internalError(
                                message: error.message,
                                error: nil
                            )
                        )
                    }
                }
            }
        }
    }

    func handleAccountSuccess(with balance: String?, completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        let balance = BigUInt(balance ?? "0") ?? BigUInt(0)
        completion(.success(result: balance.asDecimal(exponent: LskWalletService.currencyExponent)))
    }
    func handleAccountError(with error: APIError, completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        if error.message == "Unexpected Error" {
            completion(.failure(error: .networkError))
        } else {
            completion(.failure(error: .internalError(message: error.message, error: nil)))
        }
    }
    
    func getLskAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        apiService.get(key: LskWalletService.kvsAddress, sender: address, completion: completion)
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        do {
            let result = try await apiService.get(key: LskWalletService.kvsAddress, sender: address)
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            return result
        } catch let error as ApiServiceError {
            throw WalletServiceError.internalError(
                message: "LSK Wallet: failed to get address from KVS",
                error: error
            )
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
            completion(.failure(error: .notEnoughMoney))
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
    func getTransactions(offset: UInt) async throws -> [Transactions.TransactionModel] {
        guard let address = self.lskWallet?.address,
              let transactionApi = serviceApi
        else {
            throw WalletServiceError.internalError(message: "LSK Wallet: not found", error: nil)
        }
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<[Transactions.TransactionModel], Error>) in
            transactionApi.transactions(
                senderIdOrRecipientId: address,
                limit: 100,
                offset: offset,
                sort: APIRequest.Sort("timestamp", direction: .descending)
            ) { (response) in
                switch response {
                case .success(response: let result):
                    continuation.resume(returning: result)
                    
                case .error(response: let error):
                    continuation.resume(throwing: WalletServiceError.internalError(message: error.message, error: nil))
                }
            }
        }
    }
    
    func getTransaction(by hash: String) async throws -> Transactions.TransactionModel {
        guard let api = serviceApi else {
            throw ApiServiceError.internalError(message: "Problem with accessing LSK nodes, try later", error: nil)
        }
        
        return try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Transactions.TransactionModel, Error>) in
            api.transactions(id: hash, limit: 1, offset: 0) { (response) in
                switch response {
                case .success(response: let result):
                    if let transaction = result.first {
                        continuation.resume(returning: transaction)
                    } else {
                        continuation.resume(throwing: ApiServiceError.internalError(message: "No transaction", error: nil))
                    }
                case .error(response: let error):
                    print("ERROR: " + error.message)
                    continuation.resume(throwing: ApiServiceError.internalError(message: error.message, error: nil))
                }
            }
        }
    }
}

// MARK: - PrivateKey generator
extension LskWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Lisk"
    }
    
    var rowImage: UIImage? {
        return #imageLiteral(resourceName: "lisk_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let keypair = try? LiskKit.Crypto.keyPair(fromPassphrase: passphrase, salt: "adm") else {
            return nil
        }
        
        return keypair.privateKeyString
    }
}
