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
import Combine
import CommonKit

final class LskWalletService: WalletCoreProtocol {
    var wallet: WalletAccount? { return lskWallet }
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.lskWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.lskWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.lskWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.lskWallet.stateChanged")
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "lsk_transaction"
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var lskNodeApiService: LskNodeApiService!
    var lskServiceApiService: LskServiceApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var vibroService: VibroService!
    var coreDataStack: CoreDataStack!
    
    // MARK: - Constants
    var transactionFee: Decimal {
        transactionFeeRaw.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    @Atomic var transactionFeeRaw: BigUInt = BigUInt(integerLiteral: 141000)
    @Atomic private(set) var enabled = true
    @Atomic private(set) var isWarningGasPrice = false
    
    static let currencyLogo = UIImage.asset(named: "lisk_wallet") ?? .init()
    static let kvsAddress = "lsk:address"
    static let defaultFee: BigUInt = 141000
    
    @Atomic var lastHeight: UInt64 = .zero
    
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
	
    static var tokenNetworkSymbol: String {
        return "LSK"
    }
    
    var tokenContract: String {
        return ""
    }
    
    var tokenUnicID: String {
        Self.tokenNetworkSymbol + tokenSymbol
    }
    
    var richMessageType: String {
        return Self.richMessageType
	}

    var qqPrefix: String {
        return Self.qqPrefix
    }
    
    var additionalFee: Decimal {
        0.05
	}

    var nodeGroups: [NodeGroup] {
        [.lskNode, .lskService]
    }
    
	// MARK: - Properties
	let transferAvailable: Bool = true
    let netHash = Constants.Nethash.main
    
    @Atomic private(set) var lskWallet: LskWallet?
    @Atomic private var cachedWalletAddress: [String: String] = [:]
    
    let defaultDispatchQueue = DispatchQueue(
        label: "im.adamant.lskWalletService",
        qos: .utility,
        attributes: [.concurrent]
    )
    
    @Atomic private var subscriptions = Set<AnyCancellable>()

    @ObservableValue private(set) var transactions: [TransactionDetails] = []
    @ObservableValue private(set) var hasMoreOldTransactions: Bool = true

    var transactionsPublisher: AnyObservable<[TransactionDetails]> {
        $transactions.eraseToAnyPublisher()
    }
    
    var hasMoreOldTransactionsPublisher: AnyObservable<Bool> {
        $hasMoreOldTransactions.eraseToAnyPublisher()
    }
    
    private(set) lazy var coinStorage: CoinStorageService = AdamantCoinStorageService(
        coinId: tokenUnicID,
        coreDataStack: coreDataStack,
        blockchainType: richMessageType
    )
    
    // MARK: - State
    @Atomic private (set) var state: WalletServiceState = .notInitiated
    
    private func setState(_ newState: WalletServiceState, silent: Bool = false) {
        guard newState != state else {
            return
        }
        
        state = newState
        
        if !silent {
            NotificationCenter.default.post(
                name: serviceStateChanged,
                object: self,
                userInfo: [AdamantUserInfoKey.WalletService.walletState: state]
            )
        }
    }
        
    // MARK: - Delayed KVS save
    @Atomic private var balanceObserver: NSObjectProtocol?
    
    init() {
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
                self?.lskWallet = nil
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
                self?.coinStorage.clear()
                self?.hasMoreOldTransactions = true
                self?.transactions = []
            }
            .store(in: &subscriptions)
    }
    
    func addTransactionObserver() {
        coinStorage.transactionsPublisher
            .sink { [weak self] transactions in
                self?.transactions = transactions
            }
            .store(in: &subscriptions)
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
        
        if let nonce = try? await getNonce(address: wallet.address) {
            wallet.nonce = nonce
        }
        
        if let result = try? await getFees() {
            self.lastHeight = result.lastHeight
            self.transactionFeeRaw = result.fee > LskWalletService.defaultFee
            ? result.fee
            : LskWalletService.defaultFee
        }
        
        if let balance = try? await getBalance() {
            let notification: Notification.Name?
            
            let isRaised = (wallet.balance < balance) && wallet.isBalanceInitialized
            
            if wallet.balance != balance {
                wallet.balance = balance
                notification = walletUpdatedNotification
            } else if !wallet.isBalanceInitialized {
                notification = walletUpdatedNotification
            } else {
                notification = nil
            }
            
            wallet.isBalanceInitialized = true
            
            if isRaised {
                vibroService.applyVibration(.success)
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
    }
    
    // MARK: - Tools
    func validate(address: String) -> AddressValidationResult {
        return validateAddress(address)
    }

    func validateAddress(_ address: String) -> AddressValidationResult {
        return LiskKit.Crypto.isValidBase32(address: address) ? .valid : .invalid(description: nil)
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
        
        let minFeePerByte = try await lskNodeApiService.requestAccountsApi { api in
            try await api.getFees().minFeePerByte
        }.get()
        
        let tempTransaction = TransactionEntity().createTx(
            amount: 100000000.0,
            fee: 0.00141,
            nonce: wallet.nonce,
            senderPublicKey: wallet.keyPair.publicKeyString,
            recipientAddressBinary: wallet.binaryAddress
        ).sign(
            with: wallet.keyPair,
            for: Constants.chainID
        )
        
        let feeValue = tempTransaction.getFee(with: minFeePerByte)
        let fee = BigUInt(feeValue)
        
        let lastBlock = try await lskNodeApiService.requestAccountsApi { api in
            try await api.lastBlock()
        }.get()
        
        let height = UInt64(lastBlock.header.height)
        
        return (fee: fee, lastHeight: height)
    }
    
    func isExist(address: String) async throws -> Bool {
        try await lskServiceApiService.requestServiceApi { api in
            try await withUnsafeThrowingContinuation { continuation in
                api.exist(address: address) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response.data.isExists)
                    case .error(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }.get()
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension LskWalletService {
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
            let wallet = LskWallet(
                address: address,
                keyPair: keyPair,
                nonce: .zero,
                isNewApi: true
            )
            self.lskWallet = wallet
            
            NotificationCenter.default.post(
                name: walletUpdatedNotification,
                object: self,
                userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
            )
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
            
            service.setState(.upToDate)
            
            Task {
                await service.update()
            }
            
            return eWallet
        } catch let error as WalletServiceError {
            switch error {
            case .walletNotInitiated:
                /// The ADM Wallet is not initialized. Check the balance of the current wallet
                /// and save the wallet address to kvs when dropshipping ADM
                service.setState(.upToDate)
                
                Task {
                    await service.update()
                }
                
                service.save(lskAddress: eWallet.address) { result in
                    service.kvsSaveCompletionRecursion(lskAddress: eWallet.address, result: result)
                }
                
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
    @MainActor
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        lskServiceApiService = container.resolve(LskServiceApiService.self)
        lskNodeApiService = container.resolve(LskNodeApiService.self)
        vibroService = container.resolve(VibroService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
    }
}

// MARK: - Balances & addresses
extension LskWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = lskWallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        let result = await lskNodeApiService.requestAccountsApi { api in
            let balanceRaw = try await api.balance(address: address)
            let balance = BigUInt(balanceRaw?.availableBalance ?? "0") ?? .zero
            return balance
        }
        
        switch result {
        case let .success(balance):
            return balance.asDecimal(exponent: LskWalletService.currencyExponent)
        case let .failure(error):
            throw error
        }
    }
    
    func getNonce(address: String) async throws -> UInt64 {
        let nonce = try await lskNodeApiService.requestAccountsApi { api in
            try await api.nonce(address: address)
        }.get()
        
        return UInt64(nonce) ?? .zero
    }

    func handleAccountSuccess(with balance: String?, completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        let balance = BigUInt(balance ?? "0") ?? BigUInt(0)
        completion(.success(balance.asDecimal(exponent: LskWalletService.currencyExponent)))
    }
    func handleAccountError(with error: APIError, completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        if error == .noNetwork {
            completion(.failure(.networkError))
        } else {
            completion(.failure(.remoteServiceError(message: error.message)))
        }
    }
    
    func getLskAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        Task {
            let result = await apiService.get(
                key: LskWalletService.kvsAddress,
                sender: address
            )
            
            completion(result)
        }
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        do {
            let result = try await apiService.get(key: LskWalletService.kvsAddress, sender: address).get()
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            cachedWalletAddress[address] = result
            
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "LSK Wallet: failed to get address from KVS"
            )
        }
    }
    
    func loadTransactions(offset: Int, limit: Int) async throws -> Int {
        let trs = try await getTransactions(offset: UInt(offset), limit: UInt(limit))
        
        guard trs.count > 0 else {
            hasMoreOldTransactions = false
            return .zero
        }
        
        coinStorage.append(trs)
        return trs.count
    }
    
    func getLocalTransactionHistory() -> [TransactionDetails] {
        transactions
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
        
        Task {
            let result = await apiService.store(
                key: LskWalletService.kvsAddress,
                value: lskAddress,
                type: .keyValue,
                sender: adamant.address,
                keypair: keypair
            )
            
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
    func getTransactions(offset: UInt, limit: UInt = 100) async throws -> [Transactions.TransactionModel] {
        guard let address = self.lskWallet?.address else {
            throw WalletServiceError.internalError(message: "LSK Wallet: not found", error: nil)
        }
        
        return try await lskServiceApiService.requestServiceApi { api, completion in
            api.transactions(
                ownerAddress: address,
                senderIdOrRecipientId: address,
                limit: limit,
                offset: offset,
                sort: APIRequest.Sort("timestamp", direction: .descending),
                completionHandler: completion
            )
        }.get()
    }
    
    func getTransaction(by hash: String) async throws -> Transactions.TransactionModel {
        guard !hash.isEmpty else {
            throw ApiServiceError.internalError(message: "No hash", error: nil)
        }
        
        let ownerAddress = wallet?.address
        
        let result = try await lskServiceApiService.requestServiceApi { api, completion in
            api.transactions(
                ownerAddress: ownerAddress,
                id: hash,
                limit: 1,
                offset: 0,
                completionHandler: completion
            )
        }.get()
        
        if let transaction = result.first {
            return transaction
        } else {
            throw WalletServiceError.remoteServiceError(message: "No transaction")
        }
    }
    
    func updateStatus(for id: String, status: TransactionStatus?) {
        coinStorage.updateStatus(for: id, status: status)
    }
}

// MARK: - PrivateKey generator
extension LskWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        return "Lisk"
    }
    
    var rowImage: UIImage? {
        return .asset(named: "lisk_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let keypair = try? LiskKit.Crypto.keyPair(fromPassphrase: passphrase, salt: "adm") else {
            return nil
        }
        
        return keypair.privateKeyString
    }
}
