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
import Combine
import CommonKit

final class DashWalletService: WalletService {
    
    var tokenSymbol: String {
        return type(of: self).currencySymbol
    }
    
    var tokenLogo: UIImage {
        return type(of: self).currencyLogo
    }
    
    var tokenNetworkSymbol: String {
        return "DASH"
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
    var addressConverter: AddressConverter!
    
    // MARK: - Constants
    static var currencyLogo = UIImage.asset(named: "dash_wallet") ?? .init()
    
    static let multiplier = Decimal(sign: .plus, exponent: 8, significand: 1)
    static let chunkSize = 20
    
    var transactionFee: Decimal {
        return DashWalletService.fixedFee
    }
    
    private (set) var isWarningGasPrice = false
    
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
    private var balanceSubscription: AnyCancellable?
    
    // MARK: - Properties
    private (set) var dashWallet: DashWallet?
    
    private (set) var enabled = true
    
    public var network: Network
    
    private var initialBalanceCheck = false
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.dashWalletService", qos: .userInteractive, attributes: [.concurrent])
    
    static let jsonDecoder = JSONDecoder()
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
        self.network = DashMainnet()
        
        self.setState(.notInitiated)
        
        // Notifications
        addObservers()
    }
    
    func addObservers() {
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn, object: nil)
            .receive(on: OperationQueue.main)
            .asyncSink { [weak self] _ in
                await self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.accountDataUpdated, object: nil)
            .receive(on: OperationQueue.main)
            .asyncSink { [weak self] _ in
                await self?.update()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut, object: nil)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.dashWallet = nil
                self?.initialBalanceCheck = false
                self?.balanceSubscription = nil
            }
            .store(in: &subscriptions)
    }
    
    func update() {
        Task {
            await update()
        }
    }
    
    func update() async {
        guard let wallet = dashWallet else {
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
    }
    
    func validate(address: String) -> AddressValidationResult {
        let address = try? addressConverter.convert(address: address)
        
        switch address?.scriptType {
        case .p2pk, .p2pkh, .p2sh:
            return .valid
        case .p2tr, .p2multi, .p2wpkh, .p2wpkhSh, .p2wsh, .unknown, .none:
            return .invalid(description: nil)
        }
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension DashWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        setState(.initiationFailed(reason: reason))
        dashWallet = nil
    }
    
    @MainActor
    func initWallet(withPassphrase passphrase: String) async throws -> WalletAccount {
        guard let adamant = await accountService.account else {
            throw WalletServiceError.notLogged
        }
        
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        let privateKeyData = passphrase.data(using: .utf8)!.sha256()
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        let eWallet = try DashWallet(
            privateKey: privateKey,
            addressConverter: addressConverter
        )
        
        self.dashWallet = eWallet
        
        if !self.enabled {
            self.enabled = true
            NotificationCenter.default.post(name: self.serviceEnabledChanged, object: self)
        }
        
        // MARK: 4. Save address into KVS
        do {
            let address = try await getWalletAddress(byAdamantAddress: adamant.address)
            initialBalanceCheck = true
            setState(.upToDate, silent: true)
            
            Task { [weak self] in
                if address != eWallet.address {
                    guard let result = await self?.save(dashAddress: eWallet.address) else { return }
                    self?.kvsSaveCompletionRecursion(dashAddress: eWallet.address, result: result)
                }
                
                await self?.update()
            }
            return eWallet
        } catch let error as WalletServiceError {
            defer { setState(.upToDate) }
            
            switch error {
            case .walletNotInitiated:
                /// The ADM Wallet is not initialized. Check the balance of the current wallet
                /// and save the wallet address to kvs when dropshipping ADM
                
                Task { [weak self] in
                    guard let result = await self?.save(dashAddress: eWallet.address) else { return }
                    self?.kvsSaveCompletionRecursion(dashAddress: eWallet.address, result: result)
                    await self?.update()
                }
                return eWallet
                
            default:
                throw error
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
        addressConverter = container.resolve(AddressConverterFactory.self)?
            .make(network: network)
    }
}

// MARK: - Balances & addresses
extension DashWalletService {
    func getBalance() async throws -> Decimal {
        guard let address = dashWallet?.address else {
            throw WalletServiceError.walletNotInitiated
        }
        
        return try await getBalance(address: address)
    }
    
    func getBalance(address: String) async throws -> Decimal {
        guard let endpoint = DashWalletService.nodes.randomElement()?.asURL() else {
            let message = "Failed to get DASH endpoint URL"
            assertionFailure(message)
            throw WalletServiceError.internalError(message: message, error: nil)
        }

        // Parameters
        let parameters: Parameters = [
            "method": "getaddressbalance",
            "params": [
                address
            ]
        ]
        
        // MARK: Sending request
        
        let data = try await apiService.sendRequest(
            url: endpoint,
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        )
        
        let object = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? [String: Any]

        guard let object = object else {
            throw WalletServiceError.remoteServiceError(
                message: "DASH Wallet: not valid response"
            )
        }
        
        let result = object["result"] as? [String: Any]
        let error = object["error"]
        
        if error is NSNull, let result = result, let raw = result["balance"] as? Int64 {
            let balance = Decimal(raw) / DashWalletService.multiplier
            return balance
        } else {
            throw WalletServiceError.remoteServiceError(message: "DASH Wallet: \(data)")
        }
    }

    func getWalletAddress(byAdamantAddress address: String) async throws -> String {
        do {
            let result = try await apiService.get(key: DashWalletService.kvsAddress, sender: address)
            
            guard let result = result else {
                throw WalletServiceError.walletNotInitiated
            }
            
            return result
        } catch _ as ApiServiceError {
            throw WalletServiceError.remoteServiceError(
                message: "DASH Wallet: failed to get address from KVS"
            )
        }
    }
}

// MARK: - KVS
extension DashWalletService {
    /// - Parameters:
    ///   - dashAddress: DASH address to save into KVS
    ///   - adamantAddress: Owner of Dash address
    ///   - completion: success
    private func save(dashAddress: String) async -> WalletServiceSimpleResult {
        guard
            let adamant = await accountService.account,
            let keypair = await accountService.keypair
        else {
            return .failure(error: .notLogged)
        }

        guard adamant.balance >= AdamantApiService.KvsFee else {
            return .failure(error: .notEnoughMoney)
        }
        
        do {
            _ = try await apiService.store(
                key: DashWalletService.kvsAddress,
                value: dashAddress,
                type: .keyValue,
                sender: adamant.address,
                keypair: keypair
            )
            
            return .success
        } catch {
            return (error as? ApiServiceError).map { .failure(error: .apiError($0)) }
                ?? .failure(error: .internalError(message: "Unknown error", error: error))
        }
    }
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(dashAddress: String, result: WalletServiceSimpleResult) {
        balanceSubscription = nil

        switch result {
        case .success:
            break

        case .failure(let error):
            switch error {
            case .notEnoughMoney:  // Possibly new account, we need to wait for dropship
                balanceSubscription = NotificationCenter.default
                    .publisher(for: .AdamantAccountService.accountDataUpdated, object: nil)
                    .asyncSink { [weak self] _ in
                        guard
                            let balance = await self?.accountService.account?.balance,
                            balance > AdamantApiService.KvsFee
                        else { return }
                        
                        guard let result = await self?.save(dashAddress: dashAddress) else { return }
                        self?.kvsSaveCompletionRecursion(dashAddress: dashAddress, result: result)
                    }

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
        return .asset(named: "dash_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase), let privateKeyData = passphrase.data(using: .utf8)?.sha256() else {
            return nil
        }
        
        let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
        
        return privateKey.toWIF()
    }
}
