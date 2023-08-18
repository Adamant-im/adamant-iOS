//
//  AdamantAccountService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Combine
import CommonKit

actor AdamantAccountService: AccountService {
    // MARK: Dependencies
    
    private let apiService: ApiService
    private let adamantCore: AdamantCore
    private let dialogService: DialogService
    private let securedStore: SecuredStore
    private let reachabilityMonitor: ReachabilityMonitor
    private let walletsManager: WalletServicesManager
    private let visibleWalletService: VisibleWalletsService

    weak var notificationsService: NotificationsService?
    weak var currencyInfoService: CurrencyInfoService?
    weak var pushNotificationsTokenService: PushNotificationsTokenService?
    
    // MARK: Properties
    
    private(set) var state: AccountServiceState = .notLogged
    @MainActor private(set) var account: AdamantAccount?
    private(set) var keypair: Keypair?
    private var passphrase: String?
    
    private func setState(_ state: AccountServiceState) {
        self.state = state
    }
    
    @MainActor private(set) var hasStayInAccount: Bool = false
    @MainActor private var _useBiometry: Bool = false
    
    @MainActor var useBiometry: Bool {
        get { _useBiometry }
        set {
            guard hasStayInAccount else {
                _useBiometry = false
                return
            }
            
            _useBiometry = newValue
            
            if newValue {
                securedStore.set(String(useBiometry), for: .useBiometry)
            } else {
                securedStore.remove(.useBiometry)
            }
        }
    }
    
    private var previousAppState: UIApplication.State?
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        apiService: ApiService,
        adamantCore: AdamantCore,
        dialogService: DialogService,
        securedStore: SecuredStore,
        reachabilityMonitor: ReachabilityMonitor,
        walletsManager: WalletServicesManager,
        visibleWalletService: VisibleWalletsService
    ) {
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.dialogService = dialogService
        self.securedStore = securedStore
        self.reachabilityMonitor = reachabilityMonitor
        self.walletsManager = walletsManager
        self.visibleWalletService = visibleWalletService
        
        Task {
            let forceUpdateBalance = NotificationCenter.default
                .publisher(for: .AdamantAccountService.forceUpdateBalance, object: nil)
                .asyncSink { [weak self] _ in await self?.update() }
            
            let forceUpdateAllBalances = NotificationCenter.default
                .publisher(for: .AdamantAccountService.forceUpdateAllBalances, object: nil)
                .asyncSink { [weak self] _ in await self?.updateAll() }
            
            await initiateEthNetwork()
            await saveSubscription(forceUpdateBalance)
            await saveSubscription(forceUpdateAllBalances)
        }
        
        Task { @MainActor in
            let becomeActive = NotificationCenter.default
                .publisher(for: UIApplication.didBecomeActiveNotification, object: nil)
                .asyncSink { [weak self] _ in
                    guard await self?.previousAppState == .background else { return }
                    await self?.updatePreviousState(.active)
                    await self?.update()
                }
            
            let resignActive = NotificationCenter.default
                .publisher(for: UIApplication.willResignActiveNotification, object: nil)
                .asyncSink { [weak self] _ in await self?.updatePreviousState(.background) }
            
            await saveSubscription(becomeActive)
            await saveSubscription(resignActive)
            await setupSecuredStore()
        }
    }
    
    func setupWeakDeps(
        notificationsService: NotificationsService?,
        currencyInfoService: CurrencyInfoService?,
        pushNotificationsTokenService: PushNotificationsTokenService?
    ) {
        self.notificationsService = notificationsService
        self.currencyInfoService = currencyInfoService
        self.pushNotificationsTokenService = pushNotificationsTokenService
    }
    
    private func saveSubscription(_ subscription: AnyCancellable) {
        subscription.store(in: &subscriptions)
    }
    
    private func updatePreviousState(_ newValue: UIApplication.State) {
        previousAppState = newValue
    }
    
    private func initiateEthNetwork() async {
        guard let node = EthWalletService.nodes.randomElement() else {
            assertionFailure("Failed to get ETH endpoint")
            return
        }
        
        let ethWallet = await walletsManager.ethWalletService
        
        ethWallet.initiateNetwork(apiUrl: node.asString()) { [weak self, dialogService] result in
            switch result {
            case .success:
                break
                
            case .failure(let error):
                switch error {
                case .networkError:
                    Task { [weak self] in
                        await self?.repeatInitiatingEthWallet()
                    }
                    
                case .notLogged, .transactionNotFound, .notEnoughMoney, .accountNotFound, .walletNotInitiated, .invalidAmount, .requestCancelled, .dustAmountError:
                    break
                    
                case .remoteServiceError, .apiError, .internalError:
                    Task { @MainActor in
                        dialogService.showRichError(error: error)
                    }
                }
            }
        }
    }
    
    private func repeatInitiatingEthWallet() async {
        await Task.sleep(interval: 3)
        
        reachabilityMonitor.performWhenConnectionEstablished { [weak self] in
            Task { [weak self] in
                await self?.initiateEthNetwork()
            }
        }
    }
}

// MARK: - Saved data
extension AdamantAccountService {
    func setStayLoggedIn(pin: String) async -> AccountServiceResult {
        guard let account = await account, let keypair = keypair else {
            return .failure(.userNotLogged)
        }
        
        guard await !hasStayInAccount else {
            return .failure(.internalError(message: "Already has account", error: nil))
        }
        
        if let passphrase = passphrase {
            securedStore.set(passphrase, for: .passphrase)
        } else {
            securedStore.set(keypair.publicKey, for: .publicKey)
            securedStore.set(keypair.privateKey, for: .privateKey)
        }
        
        await setHasStayInAccount(true)
        
        NotificationCenter.default.post(
            name: .AdamantAccountService.stayInChanged,
            object: self,
            userInfo: [AdamantUserInfoKey.AccountService.newStayInState: true]
        )
        
        return .success(account: account, alert: nil)
    }
    
    @MainActor
    func validatePin(_ pin: String) -> Bool {
        guard let savedPin = securedStore.get(.pin) else {
            return false
        }
        
        return pin == savedPin
    }
    
    private func getSavedKeypair() -> Keypair? {
        if let publicKey = securedStore.get(.publicKey), let privateKey = securedStore.get(.privateKey) {
            return Keypair(publicKey: publicKey, privateKey: privateKey)
        }
        
        return nil
    }
    
    private func getSavedPassphrase() -> String? {
        return securedStore.get(.passphrase)
    }
    
    @MainActor
    func dropSavedAccount() {
        setUseBiometry(false)
        Key.allCases.forEach(securedStore.remove)
        setHasStayInAccount(false)
        
        NotificationCenter.default.post(
            name: .AdamantAccountService.stayInChanged,
            object: self,
            userInfo: [AdamantUserInfoKey.AccountService.newStayInState: false]
        )
        
        Task {
            await pushNotificationsTokenService?.removeCurrentToken()
            await notificationsService?.setNotificationsMode(.disabled, completion: nil)
        }
    }
    
    @MainActor
    private func setupSecuredStore() async {
        if
            securedStore.get(.passphrase) != nil ||
            securedStore.get(.publicKey) != nil &&
            securedStore.get(.privateKey) != nil &&
            securedStore.get(.pin) != nil
        {
            hasStayInAccount = true
            _useBiometry = securedStore.get(.useBiometry) != nil
        } else {
            hasStayInAccount = false
            _useBiometry = false
        }
        
        let subscription = NotificationCenter.default
            .publisher(for: .SecuredStore.securedStorePurged, object: securedStore)
            .asyncSink { [weak self] notification in
                guard let store = notification.object as? SecuredStore else { return }
                await self?.securedStorePurged(securedStore: store)
            }
        
        await saveSubscription(subscription)
    }
    
    @MainActor
    private func securedStorePurged(securedStore: SecuredStore) {
        if securedStore.get(.passphrase) != nil {
            hasStayInAccount = true
            _useBiometry = securedStore.get(.useBiometry) != nil
        } else {
            hasStayInAccount = false
            _useBiometry = false
        }
    }
    
    @MainActor
    private func setHasStayInAccount(_ newValue: Bool) {
        hasStayInAccount = newValue
    }
    
    @MainActor
    private func setUseBiometry(_ newValue: Bool) {
        useBiometry = newValue
    }
}

// MARK: - AccountService
extension AdamantAccountService {
    // MARK: Update logged account info
    @discardableResult
    func update() async -> AccountServiceResult {
        await update(updateOnlyVisible: true)
    }
    
    func updateAll() async {
        await update(updateOnlyVisible: false)
    }
    
    @discardableResult
    func update(updateOnlyVisible: Bool) async -> AccountServiceResult {
        switch state {
        case .notLogged, .isLoggingIn, .updating:
            return .failure(.userNotLogged)
            
        case .loggedIn:
            break
        }
        
        let prevState = state
        state = .updating
        
        guard
            let loggedAccount = await account,
            let publicKey = loggedAccount.publicKey
        else {
            return .failure(.userNotLogged)
        }
        
        if updateOnlyVisible {
            for wallet in await walletsManager.thirdPartyWallets where await !(visibleWalletService.isInvisible(wallet)) {
                wallet.update()
            }
        } else {
            await walletsManager.thirdPartyWallets.forEach { $0.update() }
        }
        
        do {
            let account = try await apiService.getAccount(byPublicKey: publicKey)
            
            guard let acc = await self.account, acc.address == account.address else {
                // User has logged out, we not interested anymore
                setState(.notLogged)
                return .failure(.userNotLogged)
            }
            
            if loggedAccount.balance != account.balance {
                await MainActor.run {
                    self.account = account
                    NotificationCenter.default.post(name: .AdamantAccountService.accountDataUpdated, object: self)
                }
            }
            
            setState(.loggedIn)
            await walletsManager.admWalletService.update()
            return .success(account: account, alert: nil)
        } catch {
            setState(prevState)
            
            return (error as? ApiServiceError).map { .failure(.apiError(error: $0)) }
                ?? .failure(.internalError(message: "Unknown error", error: error))
        }
    }
}

// MARK: - Log In
extension AdamantAccountService {
    // MARK: Passphrase
    @MainActor
    func loginWith(passphrase: String) async throws -> AccountServiceResult {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
            throw AccountServiceError.invalidPassphrase
        }
        
        guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
            throw AccountServiceError.internalError(message: "Failed to generate keypair for passphrase", error: nil)
        }
        
        let account = try await loginWith(keypair: keypair)
        
        // MARK: Drop saved accs
        if let storedPassphrase = await getSavedPassphrase(),
           storedPassphrase != passphrase {
            dropSavedAccount()
        }
        
        if let storedKeypair = await getSavedKeypair(),
           await storedKeypair != self.keypair {
            dropSavedAccount()
        }
        
        // Update and initiate wallet services
        await setPassphrase(passphrase)
        
        _ = await initWallets()
        
        return .success(account: account, alert: nil)
    }
    
    func setPassphrase(_ newValue: String?) {
        passphrase = newValue
    }
    
    // MARK: Pincode
    func loginWith(pincode: String) async throws -> AccountServiceResult {
        guard let storePin = securedStore.get(.pin) else {
            throw AccountServiceError.invalidPassphrase
        }
        
        guard storePin == pincode else {
            throw AccountServiceError.invalidPassphrase
        }
        
        return try await loginWithStoredAccount()
    }
    
    // MARK: Biometry
    @MainActor
    func loginWithStoredAccount() async throws -> AccountServiceResult {
        if let passphrase = await getSavedPassphrase() {
            let account = try await loginWith(passphrase: passphrase)
            return account
        }
        
        if let keypair = await getSavedKeypair() {
            let account = try await loginWith(keypair: keypair)
            
            let alert: (title: String, message: String)?
            if securedStore.get(.showedV12) != nil {
                alert = nil
            } else {
                securedStore.set("1", for: .showedV12)
                alert = (title: String.adamant.accountService.updateAlertTitleV12,
                         message: String.adamant.accountService.updateAlertMessageV12)
            }
            
            for case let wallet as InitiatedWithPassphraseService in walletsManager.wallets {
                wallet.setInitiationFailed(reason: String.adamant.accountService.reloginToInitiateWallets)
            }
            
            return .success(account: account, alert: alert)
        }
        
        throw AccountServiceError.invalidPassphrase
    }
    
    // MARK: Keypair
    private func loginWith(keypair: Keypair) async throws -> AdamantAccount {
        switch state {
        case .isLoggingIn:
            throw AccountServiceError.internalError(message: "Service is busy", error: nil)
        case .updating:
            fallthrough
            
        // Logout first
        case .loggedIn:
            await logout()
            
        // Go login
        case .notLogged:
            break
        }
        
        state = .isLoggingIn
        
        do {
            let account = try await apiService.getAccount(byPublicKey: keypair.publicKey)
            await MainActor.run { self.account = account }
            self.keypair = keypair
            
            let userInfo = [AdamantUserInfoKey.AccountService.loggedAccountAddress: account.address]
            
            NotificationCenter.default.post(
                name: Notification.Name.AdamantAccountService.userLoggedIn,
                object: self,
                userInfo: userInfo
            )
            
            self.setState(.loggedIn)
            
            return account
        } catch let error as ApiServiceError {
            self.setState(.notLogged)
            
            switch error {
            case .accountNotFound:
                throw AccountServiceError.wrongPassphrase
                
            default:
                throw AccountServiceError.apiError(error: error)
            }
        } catch {
            throw AccountServiceError.internalError(message: error.localizedDescription, error: error)
        }
    }
    
    func reloadWallets() {
        Task {
            _ = await initWallets()
        }
    }
    
    func initWallets() async -> [WalletAccount?] {
        guard let passphrase = passphrase else {
            print("No passphrase found")
            return []
        }
        
        return await withTaskGroup(of: WalletAccount?.self) { group in
            for case let wallet as InitiatedWithPassphraseService in await walletsManager.wallets {
                group.addTask {
                    let result = try? await wallet.initWallet(withPassphrase: passphrase)
                    return result
                }
            }
            
            var wallets: [WalletAccount?] = []
            
            for await wallet in group {
                wallets.append(wallet)
            }

            return wallets
        }
    }
}

// MARK: - Log Out
extension AdamantAccountService {
    @MainActor
    func logout() {
        if account != nil {
            NotificationCenter.default.post(
                name: .AdamantAccountService.userWillLogOut,
                object: self
            )
        }
        
        let wasLogged = account != nil
        Task { await resetDataOnLogout() }
        
        guard wasLogged else { return }
        NotificationCenter.default.post(name: .AdamantAccountService.userLoggedOut, object: self)
    }
    
    func resetDataOnLogout() async {
        keypair = nil
        passphrase = nil
        state = .notLogged
        
        await MainActor.run {
            account = nil
            dropSavedAccount()
        }
    }
}

private enum Key: CaseIterable {
    case publicKey
    case privateKey
    case pin
    case useBiometry
    case passphrase
    case showedV12
    case blockListKey
    case removedMessages
    
    var stringValue: String {
        switch self {
        case .publicKey: return StoreKey.accountService.publicKey
        case .privateKey: return StoreKey.accountService.privateKey
        case .pin: return StoreKey.accountService.pin
        case .useBiometry: return StoreKey.accountService.useBiometry
        case .passphrase: return StoreKey.accountService.passphrase
        case .showedV12: return StoreKey.accountService.showedV12
        case .blockListKey: return StoreKey.accountService.blockList
        case .removedMessages: return StoreKey.accountService.removedMessages
        }
    }
}

private extension SecuredStore {
    func set(_ value: String, for key: Key) {
        set(value, for: key.stringValue)
    }
    
    func get(_ key: Key) -> String? {
        return get(key.stringValue)
    }
    
    func remove(_ key: Key) {
        remove(key.stringValue)
    }
}
