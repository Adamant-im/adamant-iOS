//
//  KlyWalletService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 08.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import Swinject
import UIKit
import CommonKit
import Combine
@preconcurrency import struct BigInt.BigUInt
@preconcurrency import LiskKit

final class KlyWalletService: WalletCoreProtocol, @unchecked Sendable {
    struct CurrentFee: Sendable {
        let fee: BigUInt
        let lastHeight: UInt64
        let minFeePerByte: UInt64
    }
    
    // MARK: Dependencies
    
    var apiService: AdamantApiServiceProtocol!
    var klyNodeApiService: KlyNodeApiService!
    var klyServiceApiService: KlyServiceApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var vibroService: VibroService!
    var coreDataStack: CoreDataStack!
    
    // MARK: Proprieties
    
    static let richMessageType = "kly_transaction"
    static let currencyLogo = UIImage.asset(named: "klayr_wallet") ?? .init()
    static let kvsAddress = "kly:address"
    static let defaultFee: BigUInt = 141000
    
    @MainActor
    var hasEnabledNode: Bool {
        klyNodeApiService.hasEnabledNode && klyServiceApiService.hasEnabledNode
    }
    
    @MainActor
    var hasEnabledNodePublisher: AnyObservable<Bool> {
        klyNodeApiService.hasEnabledNodePublisher
            .combineLatest(klyServiceApiService.hasEnabledNodePublisher)
            .map { $0.0 && $0.1 }
            .eraseToAnyPublisher()
    }
    
    @Atomic var transactionFeeRaw: BigUInt = BigUInt(integerLiteral: 141000)
    
    @Atomic private var cachedWalletAddress: [String: String] = [:]
    @Atomic private var subscriptions = Set<AnyCancellable>()
    @Atomic private var balanceObserver: AnyCancellable?
    
    @Atomic private(set) var klyWallet: KlyWallet?
    @Atomic private(set) var enabled = true
    @Atomic private(set) var isWarningGasPrice = false
    @Atomic private(set) var state: WalletServiceState = .notInitiated
    @Atomic private(set) var lastHeight: UInt64 = .zero
    @Atomic private(set) var lastMinFeePerByte: UInt64 = .zero
    @Atomic private var balanceInvalidationSubscription: AnyCancellable?
    
    @ObservableValue private(set) var transactions: [TransactionDetails] = []
    @ObservableValue private(set) var hasMoreOldTransactions: Bool = true
    
    private(set) lazy var coinStorage: CoinStorageService = AdamantCoinStorageService(
        coinId: tokenUnicID,
        coreDataStack: coreDataStack,
        blockchainType: richMessageType
    )
    
    let salt = "adm"
    
    // MARK: Notifications
    
    let walletUpdatedNotification = Notification.Name("adamant.klyWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.klyWallet.enabledChanged")
    let transactionFeeUpdated = Notification.Name("adamant.klyWallet.feeUpdated")
    let serviceStateChanged = Notification.Name("adamant.klyWallet.stateChanged")
    
    init() {
        addObservers()
    }
    
    // MARK: -
    
    func initWallet(
        withPassphrase passphrase: String, withPassword password: String
    ) async throws -> WalletAccount {
        try await initWallet(passphrase: passphrase, password: password)
    }
    
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        klyWallet = nil
    }
    
    func update() {
        Task {
            await update()
        }
    }
    
    func updateStatus(for id: String, status: TransactionStatus?) {
        coinStorage.updateStatus(for: id, status: status)
    }
    
    func validate(address: String) -> AddressValidationResult {
        LiskKit.Crypto.isValidBase32(address: address)
        ? .valid
        : .invalid(description: nil)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        try await getBalance(for: address)
    }
    
    func getCurrentFee() async throws -> CurrentFee {
        try await getFees(comment: .empty)
    }
    
    func getFee(comment: String) -> Decimal {
        let fee = try? getFee(
            minFeePerByte: lastMinFeePerByte,
            comment: comment
        ).asDecimal(exponent: Self.currencyExponent)
        
        return fee ?? transactionFee
    }
    
    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        try await getKlyWalletAddress(byAdamantAddress: address)
    }
    
    func getLocalTransactionHistory() -> [TransactionDetails] {
        transactions
    }
    
    func getTransactionsHistory(
        offset: Int,
        limit: Int
    ) async throws -> [TransactionDetails] {
        try await getTransactions(offset: UInt(offset), limit: UInt(limit))
    }
    
    func loadTransactions(offset: Int, limit: Int) async throws -> Int {
        let trs = try await getTransactionsHistory(offset: offset, limit: limit)
        
        guard trs.count > 0 else {
            hasMoreOldTransactions = false
            return .zero
        }
        
        coinStorage.append(trs)
        return trs.count
    }
    
    func getTransaction(
        by hash: String,
        waitsForConnectivity: Bool
    ) async throws -> Transactions.TransactionModel {
        try await getTransaction(hash: hash, waitsForConnectivity: waitsForConnectivity)
    }
    
    func isExist(address: String) async throws -> Bool {
        try await isAccountExist(with: address)
    }
}

// MARK: - Dependencies
extension KlyWalletService: SwinjectDependentService {
    @MainActor
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(AdamantApiServiceProtocol.self)
        dialogService = container.resolve(DialogService.self)
        klyServiceApiService = container.resolve(KlyServiceApiService.self)
        klyNodeApiService = container.resolve(KlyNodeApiService.self)
        vibroService = container.resolve(VibroService.self)
        coreDataStack = container.resolve(CoreDataStack.self)
        
        addTransactionObserver()
    }
    
    func addTransactionObserver() {
        coinStorage.transactionsPublisher
            .sink { [weak self] transactions in
                self?.transactions = transactions
            }
            .store(in: &subscriptions)
    }
}

private extension KlyWalletService {
    func addObservers() {
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.accountDataUpdated, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.klyWallet = nil
                
                if let balanceObserver = self?.balanceObserver {
                    NotificationCenter.default.removeObserver(balanceObserver)
                    self?.balanceObserver = nil
                }
                self?.coinStorage.clear()
                self?.hasMoreOldTransactions = true
                self?.transactions = []
                self?.balanceInvalidationSubscription = nil
            }
            .store(in: &subscriptions)
    }
    
    @MainActor
    func update() async {
        guard let wallet = klyWallet else {
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
            if wallet.balance < balance, wallet.isBalanceInitialized {
                vibroService.applyVibration(.success)
            }
            
            wallet.balance = balance
            markBalanceAsFresh(wallet)
            
            NotificationCenter.default.post(
                name: walletUpdatedNotification,
                object: self,
                userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
            )
        }
        
        if let nonce = try? await getNonce(address: wallet.address) {
            wallet.nonce = nonce
        }
        
        if let result = try? await getFees(comment: .empty) {
            self.lastHeight = result.lastHeight
            self.transactionFeeRaw = result.fee > KlyWalletService.defaultFee
            ? result.fee
            : KlyWalletService.defaultFee
            self.lastMinFeePerByte = result.minFeePerByte
        }
        
        setState(.upToDate)
    }
    
    func markBalanceAsFresh(_ wallet: KlyWallet) {
        wallet.isBalanceInitialized = true
        
        balanceInvalidationSubscription = Task { [weak self] in
            try await Task.sleep(interval: Self.balanceLifetime, pauseInBackground: true)
            guard let self else { return }
            wallet.isBalanceInitialized = false
            
            NotificationCenter.default.post(
                name: walletUpdatedNotification,
                object: self,
                userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
            )
        }.eraseToAnyCancellable()
    }
}

private extension KlyWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = klyWallet?.address else {
            throw WalletServiceError.notLogged
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(for address: String) async throws -> Decimal {
        let result = await klyNodeApiService.requestAccountsApi { api in
            let balanceRaw = try await api.balance(address: address)
            let balance = BigUInt(balanceRaw?.availableBalance ?? "0") ?? .zero
            return balance
        }
        
        switch result {
        case let .success(balance):
            return balance.asDecimal(exponent: KlyWalletService.currencyExponent)
        case let .failure(error):
            throw error
        }
    }
    
    func getNonce(address: String) async throws -> UInt64 {
        let nonce = try await klyNodeApiService.requestAccountsApi { api in
            try await api.nonce(address: address)
        }.get()
        
        return UInt64(nonce) ?? .zero
    }
    
    func getFees(comment: String) async throws -> CurrentFee {
        guard let wallet = klyWallet else {
            throw WalletServiceError.notLogged
        }
        
        let minFeePerByte = try await klyNodeApiService.requestAccountsApi { api in
            try await api.getFees().minFeePerByte
        }.get()
        
        let tempTransaction = TransactionEntity().createTx(
            amount: 100000000.0,
            fee: 0.00141,
            nonce: wallet.nonce,
            senderPublicKey: wallet.keyPair.publicKeyString,
            recipientAddressBinary: wallet.binaryAddress,
            comment: comment
        ).sign(
            with: wallet.keyPair,
            for: Constants.chainID
        )
        
        let feeValue = tempTransaction.getFee(with: minFeePerByte)
        let fee = BigUInt(feeValue)
        
        let lastBlock = try await klyNodeApiService.requestAccountsApi { api in
            try await api.lastBlock()
        }.get()
        
        let height = UInt64(lastBlock.header.height)
        
        return .init(fee: fee, lastHeight: height, minFeePerByte: minFeePerByte)
    }
    
    func getFee(minFeePerByte: UInt64, comment: String) throws -> BigUInt {
        guard let wallet = klyWallet else {
            throw WalletServiceError.notLogged
        }
        
        let tempTransaction = TransactionEntity().createTx(
            amount: 100000000.0,
            fee: 0.00141,
            nonce: wallet.nonce,
            senderPublicKey: wallet.keyPair.publicKeyString,
            recipientAddressBinary: wallet.binaryAddress,
            comment: comment
        ).sign(
            with: wallet.keyPair,
            for: Constants.chainID
        )
        
        let feeValue = tempTransaction.getFee(with: minFeePerByte)
        let fee = BigUInt(feeValue)
        
        return fee
    }
    
    func setState(_ newState: WalletServiceState, silent: Bool = false) {
        guard newState != state else {
            return
        }
        
        state = newState
        
        guard !silent else { return }
        
        NotificationCenter.default.post(
            name: serviceStateChanged,
            object: self,
            userInfo: [AdamantUserInfoKey.WalletService.walletState: state]
        )
    }
}

// MARK: - Init Wallet
private extension KlyWalletService {
    func initWallet(passphrase: String, password: String) async throws -> WalletAccount {
        guard let adamant = accountService.account else {
            throw WalletServiceError.notLogged
        }
        
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        do {
            let keyPair = try LiskKit.Crypto.keyPair(
                fromPassphrase: passphrase,
                salt: password.isEmpty ? salt : "mnemonic\(password)"
            )
            
            let address = LiskKit.Crypto.address(fromPublicKey: keyPair.publicKeyString)
            
            let wallet = KlyWallet(
                unicId: tokenUnicID,
                address: address,
                keyPair: keyPair,
                nonce: .zero,
                isNewApi: true
            )
            self.klyWallet = wallet
            
            NotificationCenter.default.post(
                name: walletUpdatedNotification,
                object: self,
                userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet]
            )
        } catch {
            throw WalletServiceError.accountNotFound
        }
        
        if !enabled {
            enabled = true
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        guard
            let eWallet = klyWallet,
            let kvsAddressModel = makeKVSAddressModel(wallet: eWallet)
        else {
            throw WalletServiceError.accountNotFound
        }
        
        // Save into KVS
        
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            
            if address != eWallet.address {
                updateKvsAddress(kvsAddressModel)
            }
            
            setState(.upToDate)
            
            Task {
                await update()
            }
            
            return eWallet
        } catch let error as WalletServiceError {
            switch error {
            case .walletNotInitiated:
                /// The ADM Wallet is not initialized. Check the balance of the current wallet
                /// and save the wallet address to kvs when dropshipping ADM
                setState(.upToDate)
                
                Task {
                    await update()
                }
                
                updateKvsAddress(kvsAddressModel)
                
                return eWallet
            default:
                setState(.upToDate)
                throw error
            }
        }
    }
    
    func updateKvsAddress(_ model: KVSValueModel) {
        Task {
            do {
                try await save(model)
            } catch {
                kvsSaveProcessError(
                    model,
                    error: error
                )
            }
        }
    }
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    func kvsSaveProcessError(
        _ model: KVSValueModel,
        error: Error
    ) {
        guard let error = error as? WalletServiceError,
              case .notEnoughMoney = error
        else { return }
        
        balanceObserver?.cancel()
        
        balanceObserver = NotificationCenter.default
            .notifications(named: .AdamantAccountService.accountDataUpdated)
            .compactMap { [weak self] _ in
                self?.accountService.account?.balance
            }
            .filter { $0 > AdamantApiService.KvsFee }
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                Task {
                    try await self.save(model)
                    self.balanceObserver?.cancel()
                }
            }
    }
    
    /// - Parameters:
    ///   - klyAddress: Klayr address to save into KVS
    ///   - adamantAddress: Owner of Klayr address
    func save(_ model: KVSValueModel) async throws {
        guard let adamant = accountService.account else {
            throw WalletServiceError.notLogged
        }
        
        guard adamant.balance >= AdamantApiService.KvsFee else {
            throw WalletServiceError.notEnoughMoney
        }
        
        let result = await apiService.store(model, date: .now)
        
        guard case .failure(let error) = result else {
            return
        }
        
        throw WalletServiceError.apiError(error)
    }
    
    func makeKVSAddressModel(wallet: WalletAccount) -> KVSValueModel? {
        guard let keypair = accountService.keypair else { return nil }
        
        return .init(
            key: Self.kvsAddress,
            value: wallet.address,
            keypair: keypair
        )
    }
    
    func getKlyWalletAddress(
        byAdamantAddress address: String
    ) async throws -> String {
        if let address = cachedWalletAddress[address], !address.isEmpty {
            return address
        }
        
        do {
            let result = try await apiService.get(
                key: KlyWalletService.kvsAddress,
                sender: address
            ).get()
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            cachedWalletAddress[address] = result
            
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "KLY Wallet: failed to get address from KVS"
            )
        }
    }
}

private extension KlyWalletService {
    func getTransactions(
        offset: UInt,
        limit: UInt = 100
    ) async throws -> [Transactions.TransactionModel] {
        guard let address = self.klyWallet?.address else {
            throw WalletServiceError.internalError(message: "KLY Wallet: not found", error: nil)
        }
        
        return try await klyServiceApiService.requestServiceApi(waitsForConnectivity: false) { api, completion in
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
    
    func getTransaction(hash: String, waitsForConnectivity: Bool) async throws -> Transactions.TransactionModel {
        guard !hash.isEmpty else {
            throw ApiServiceError.internalError(message: "No hash", error: nil)
        }
        
        let ownerAddress = klyWallet?.address
        
        let result = try await klyServiceApiService.requestServiceApi(
            waitsForConnectivity: waitsForConnectivity
        ) { api, completion in
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
        }
        
        throw WalletServiceError.remoteServiceError(message: "No transaction")
    }
    
    func isAccountExist(with address: String) async throws -> Bool {
        try await klyServiceApiService.requestServiceApi(waitsForConnectivity: false) { api in
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
