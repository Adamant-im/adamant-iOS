//
//  AdamantAccountService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Combine
import CommonKit
import Foundation
import UIKit

final class AdamantAccountService: AccountService, @unchecked Sendable {

    // MARK: Dependencies

    private let apiService: AdamantApiServiceProtocol
    private let adamantCore: AdamantCore
    private let SecureStore: SecureStore
    private let walletServiceCompose: WalletServiceCompose
    private let currencyInfoService: InfoServiceProtocol
    private let coreDataStack: CoreDataStack

    weak var notificationsService: NotificationsService?
    weak var pushNotificationsTokenService: PushNotificationsTokenService?
    var walletsStoreService: WalletStoreServiceProtocol?

    // MARK: Properties

    @Atomic private(set) var state: AccountServiceState = .notLogged
    @Atomic private(set) var isBalanceExpired = true
    @Atomic private(set) var account: AdamantAccount?
    @Atomic private(set) var keypair: Keypair?
    @Atomic private var passphrase: String?
    @Atomic private(set) var hasStayInAccount = false
    @Atomic private(set) var useBiometry = false
    @Atomic private var previousAppState: UIApplication.State?
    @Atomic private var subscriptions = Set<AnyCancellable>()
    @Atomic private var balanceInvalidationSubscription: AnyCancellable?

    init(
        apiService: AdamantApiServiceProtocol,
        adamantCore: AdamantCore,
        SecureStore: SecureStore,
        walletServiceCompose: WalletServiceCompose,
        currencyInfoService: InfoServiceProtocol,
        coreDataStack: CoreDataStack,
        connection: AnyObservable<Bool>
    ) {
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.SecureStore = SecureStore
        self.walletServiceCompose = walletServiceCompose
        self.currencyInfoService = currencyInfoService
        self.coreDataStack = coreDataStack

        NotificationCenter.default.addObserver(forName: .AdamantAccountService.forceUpdateBalance, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.update()
        }

        NotificationCenter.default.addObserver(forName: .AdamantAccountService.forceUpdateAllBalances, object: nil, queue: OperationQueue.main) {
            [weak self] _ in
            self?.updateAll()
        }

        NotificationCenter.default
            .notifications(named: UIApplication.didBecomeActiveNotification, object: nil)
            .sink { @MainActor [weak self] _ in
                guard self?.previousAppState == .background else { return }
                self?.previousAppState = .active
                self?.update()
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .notifications(named: UIApplication.willResignActiveNotification, object: nil)
            .sink { @MainActor [weak self] _ in
                self?.previousAppState = .background
            }
            .store(in: &subscriptions)

        connection.filter { $0 }.sink { [weak self] _ in
            self?.update()
        }.store(in: &subscriptions)

        setupSecureStore()
    }
}

// MARK: - Saved data
extension AdamantAccountService {
    func setStayLoggedIn(pin: String, completion: @escaping @Sendable (AccountServiceResult) -> Void) {
        guard let account = account, let keypair = keypair else {
            completion(.failure(.userNotLogged))
            return
        }

        if hasStayInAccount {
            completion(.failure(.internalError(message: "Already has account", error: nil)))
            return
        }

        SecureStore.set(pin, for: .pin)

        if let passphrase = passphrase {
            SecureStore.set(passphrase, for: .passphrase)
        } else {
            SecureStore.set(keypair.publicKey, for: .publicKey)
            SecureStore.set(keypair.privateKey, for: .privateKey)
        }

        hasStayInAccount = true
        NotificationCenter.default.post(
            name: Notification.Name.AdamantAccountService.stayInChanged,
            object: self,
            userInfo: [AdamantUserInfoKey.AccountService.newStayInState: true]
        )
        completion(.success(account: account, alert: nil))
    }

    func validatePin(_ pin: String) -> Bool {
        guard let savedPin = SecureStore.get(.pin) else {
            return false
        }

        return pin == savedPin
    }

    private func getSavedKeypair() -> Keypair? {
        if let publicKey = SecureStore.get(.publicKey), let privateKey = SecureStore.get(.privateKey) {
            return Keypair(publicKey: publicKey, privateKey: privateKey)
        }

        return nil
    }

    private func getSavedPassphrase() -> String? {
        return SecureStore.get(.passphrase)
    }
    
    func getCurrentPassphrase() -> String? {
        passphrase
    }
    
    func dropSavedAccount() {
        useBiometry = false
        isBalanceExpired = true
        pushNotificationsTokenService?.removeCurrentToken()
        balanceInvalidationSubscription = nil
        Key.allCases.forEach(SecureStore.remove)

        hasStayInAccount = false
        NotificationCenter.default.post(
            name: Notification.Name.AdamantAccountService.stayInChanged,
            object: self,
            userInfo: [AdamantUserInfoKey.AccountService.newStayInState: false]
        )

        Task { @MainActor in notificationsService?.setNotificationsMode(.disabled, completion: nil) }
    }

    private func markBalanceAsFresh() {
        isBalanceExpired = false

        balanceInvalidationSubscription = Task { [weak self] in
            try await Task.sleep(
                interval: AdmWalletService.balanceLifetime,
                pauseInBackground: true
            )

            guard let self else { return }
            isBalanceExpired = true
            NotificationCenter.default.post(
                name: .AdamantAccountService.accountDataUpdated,
                object: self
            )
        }.eraseToAnyCancellable()
    }

    private func setupSecureStore() {
        if SecureStore.get(.passphrase) != nil {
            hasStayInAccount = true
            useBiometry = SecureStore.get(.useBiometry) != nil
        } else if SecureStore.get(.publicKey) != nil,
            SecureStore.get(.privateKey) != nil,
            SecureStore.get(.pin) != nil
        {
            hasStayInAccount = true

            useBiometry = SecureStore.get(.useBiometry) != nil
        } else {
            hasStayInAccount = false
            useBiometry = false
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.SecureStore.SecureStorePurged, object: SecureStore, queue: OperationQueue.main) {
            [weak self] notification in
            guard let store = notification.object as? SecureStore else {
                return
            }

            if store.get(.passphrase) != nil {
                self?.hasStayInAccount = true
                self?.useBiometry = store.get(.useBiometry) != nil
            } else {
                self?.hasStayInAccount = false
                self?.useBiometry = false
            }
        }
    }

    func updateUseBiometry(_ newValue: Bool) {
        $useBiometry.mutate {
            $0 = newValue && hasStayInAccount

            if $0 {
                SecureStore.set(String($0), for: .useBiometry)
            } else {
                SecureStore.remove(.useBiometry)
            }
        }
    }
}

// MARK: - AccountService
extension AdamantAccountService {
    // MARK: Update logged account info
    func update() {
        self.update(nil)
    }

    func updateAll() {
        update(nil, updateOnlyVisible: false)
    }

    func update(_ completion: (@Sendable (AccountServiceResult) -> Void)?) {
        update(completion, updateOnlyVisible: true)
    }
    
    func updateWithRefreshUI() {
        update(nil, updateOnlyVisible: true, shouldUpdateUIBalance: true)
    }

    func update(_ completion: (@Sendable (AccountServiceResult) -> Void)?, updateOnlyVisible: Bool, shouldUpdateUIBalance: Bool = false) {
        switch state {
        case .notLogged, .isLoggingIn, .updating:
            return

        case .loggedIn:
            break
        }

        let prevState = state
        state = .updating

        guard let loggedAccount = account, let publicKey = loggedAccount.publicKey else {
            return
        }

        let wallets = walletServiceCompose.getWallets()

        Task { @Sendable in
            let result = await apiService.getAccount(byPublicKey: publicKey)

            switch result {
            case .success(let account):
                guard let acc = self.account, acc.address == account.address else {
                    // User has logged out, we not interested anymore
                    state = .notLogged
                    return
                }

                markBalanceAsFresh()
                self.account = account

                NotificationCenter.default.post(
                    name: .AdamantAccountService.accountDataUpdated,
                    object: self
                )

                state = .loggedIn
                completion?(.success(account: account, alert: nil))

            case .failure(let error):
                completion?(.failure(.apiError(error: error)))
                isBalanceExpired = true
                state = prevState
            }
        }

        for wallet in wallets {
            if !updateOnlyVisible || !(walletsStoreService?.isInvisible(wallet) ?? false) {
                if shouldUpdateUIBalance {
                    wallet.core.updateWithRefreshUIBalance()
                } else {
                    wallet.core.update()
                }
            }
        }
    }
}

// MARK: - Log In
extension AdamantAccountService {
    // MARK: Passphrase
    @MainActor
    func loginWith(passphrase: String, password: String) async throws -> AccountServiceResult {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
            throw AccountServiceError.invalidPassphrase
        }

        guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase, password: password) else {
            throw AccountServiceError.internalError(message: "Failed to generate keypair for passphrase", error: nil)
        }

        let account = try await loginWith(keypair: keypair)

        // MARK: Drop saved accs
        if let storedPassphrase = self.getSavedPassphrase(),
            storedPassphrase != passphrase
        {
            dropSavedAccount()
        }

        if let storedKeypair = self.getSavedKeypair(),
            storedKeypair != self.keypair
        {
            dropSavedAccount()
        }

        // Update and initiate wallet services
        self.passphrase = passphrase

        _ = await initWallets()
        
        let userInfo = [AdamantUserInfoKey.AccountService.loggedAccountAddress: account.address]
        
        NotificationCenter.default.post(
            name: Notification.Name.AdamantAccountService.userLoggedIn,
            object: self,
            userInfo: userInfo
        )
        
        return .success(account: account, alert: nil)
    }

    // MARK: Pincode
    func loginWith(pincode: String) async throws -> AccountServiceResult {
        guard let storePin = SecureStore.get(.pin) else {
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
        if let passphrase = getSavedPassphrase() {
            let account = try await loginWith(passphrase: passphrase, password: .empty)
            return account
        }

        if let keypair = getSavedKeypair() {
            let account = try await loginWith(keypair: keypair)

            let alert: (title: String, message: String)?
            if SecureStore.get(.showedV12) != nil {
                alert = nil
            } else {
                SecureStore.set("1", for: .showedV12)
                alert = (
                    title: String.adamant.accountService.updateAlertTitleV12,
                    message: String.adamant.accountService.updateAlertMessageV12
                )
            }

            for wallet in walletServiceCompose.getWallets() {
                wallet.core.setInitiationFailed(reason: .adamant.accountService.reloginToInitiateWallets)
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

        // Logout first
        case .updating, .loggedIn:
            logout()

        // Go login
        case .notLogged:
            break
        }

        state = .isLoggingIn

        do {
            let account = try await apiService.getAccount(byPublicKey: keypair.publicKey).get()
            self.account = account
            self.keypair = keypair
            markBalanceAsFresh()
            
            self.state = .loggedIn
            return account
        } catch let error as ApiServiceError {
            self.state = .notLogged

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

    func reloadWallets() async {
        _ = await initWallets()
    }

    func initWallets() async -> [WalletAccount?] {
        guard let passphrase = passphrase else {
            print("No passphrase found")
            return []
        }

        return await withTaskGroup(of: WalletAccount?.self) { group in
            for wallet in walletServiceCompose.getWallets() {
                group.addTask {
                    let result = try? await wallet.core.initWallet(
                        withPassphrase: passphrase,
                        withPassword: .empty,
                        storeInKVS: true
                    )
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
    func logout() {
        if account != nil {
            NotificationCenter.default.post(name: Notification.Name.AdamantAccountService.userWillLogOut, object: self)
        }

        dropSavedAccount()

        let wasLogged = account != nil
        account = nil
        keypair = nil
        passphrase = nil
        state = .notLogged
        apiService.cancelCurrentTasks()
        coreDataStack.clearCoreData()

        guard wasLogged else { return }
        NotificationCenter.default.post(name: .AdamantAccountService.userLoggedOut, object: self)
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

extension SecureStore {
    fileprivate func set(_ value: String, for key: Key) {
        set(value, for: key.stringValue)
    }

    fileprivate func get(_ key: Key) -> String? {
        return get(key.stringValue)
    }

    fileprivate func remove(_ key: Key) {
        remove(key.stringValue)
    }
}
