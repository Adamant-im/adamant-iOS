//
//  AdamantPushNotificationsTokenService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import CommonKit
import Foundation

final class AdamantPushNotificationsTokenService: PushNotificationsTokenService, @unchecked Sendable {
    private let SecureStore: SecureStore
    private let apiService: AdamantApiServiceProtocol
    private let adamantCore: AdamantCore
    private let accountService: AccountService

    private let tokenProcessingQueue = DispatchQueue(label: "com.adamant.push-token-processing-queue")
    private let tokenProcessingSemaphore = DispatchSemaphore(value: 1)
    private let SecureStoreSemaphore = DispatchSemaphore(value: 1)

    init(
        SecureStore: SecureStore,
        apiService: AdamantApiServiceProtocol,
        adamantCore: AdamantCore,
        accountService: AccountService
    ) {
        self.SecureStore = SecureStore
        self.apiService = apiService
        self.adamantCore = adamantCore
        self.accountService = accountService
    }

    func setToken(_ token: Data) {
        tokenProcessingQueue.async { [weak self] in
            self?._setToken(token)
        }
    }

    func removeCurrentToken() {
        tokenProcessingQueue.async { [weak self] in
            self?._removeCurrentToken()
        }
    }

    func sendTokenDeletionTransactions() {
        for transaction in getTokenDeletionTransactions() {
            Task {
                let result = await apiService.sendTransaction(
                    path: ApiCommands.Chats.processTransaction,
                    transaction: transaction
                )

                switch result {
                case .success, .failure(.accountNotFound), .failure(.notLogged):
                    removeTokenDeletionTransaction(transaction)
                case .failure(.internalError), .failure(.networkError), .failure(.requestCancelled), .failure(.serverError), .failure(.commonError),
                    .failure(.noEndpointsAvailable):
                    break
                }
            }
        }
    }
}

extension AdamantPushNotificationsTokenService {
    fileprivate typealias EncodedPayload = (message: String, nonce: String)

    fileprivate var ansProvider: ANSPayload.Provider {
        #if DEBUG
            return .apnsSandbox
        #else
            return .apns
        #endif
    }

    fileprivate func _setToken(_ token: Data) {
        tokenProcessingSemaphore.wait()
        guard let keypair = accountService.keypair else {
            assertionFailure("Trying to register with no user logged")
            tokenProcessingSemaphore.signal()
            return
        }

        let token = mapToken(token)
        AdamantUtilities.consoleLog("APNS token:", token)

        guard token != getToken() else {
            tokenProcessingSemaphore.signal()
            return
        }

        updateCurrentToken(newToken: token, keypair: keypair) { [weak self] in
            self?.tokenProcessingSemaphore.signal()
        }
    }

    fileprivate func _removeCurrentToken() {
        tokenProcessingSemaphore.wait()
        guard let keypair = accountService.keypair else {
            assertionFailure("Trying to unregister with no user logged")
            tokenProcessingSemaphore.signal()
            return
        }

        removeCurrentToken(keypair: keypair) { [weak self] in
            self?.tokenProcessingSemaphore.signal()
        }
    }

    fileprivate func mapToken(_ token: Data) -> String {
        token.map { String(format: "%02.2hhx", $0) }.joined()
    }

    fileprivate func updateCurrentToken(newToken: String, keypair: Keypair, completion: @escaping @Sendable () -> Void) {
        guard let encodedPayload = makeEncodedPayload(token: newToken, keypair: keypair, action: .add) else {
            return completion()
        }

        removeCurrentToken(keypair: keypair) { [weak self] in
            self?.sendMessageToANS(
                keypair: keypair,
                encodedPayload: encodedPayload
            ) { [weak self] success in
                defer { completion() }
                guard success else { return }
                self?.setTokenToStorage(newToken)
            }
        }
    }

    fileprivate func removeCurrentToken(keypair: Keypair, completion: @escaping @Sendable () -> Void) {
        guard
            let token = getToken(),
            let encodedPayload = makeEncodedPayload(
                token: token,
                keypair: keypair,
                action: .remove
            )
        else { return completion() }

        setTokenToStorage(nil)

        let transaction = Atomic<UnregisteredTransaction?>(nil)

        transaction.value = sendMessageToANS(
            keypair: keypair,
            encodedPayload: encodedPayload
        ) { [weak self] success in
            defer { completion() }
            guard !success, let self = self, let transaction = transaction.value else { return }
            self.addTokenDeletionTransaction(transaction)
        }
    }

    fileprivate func makeEncodedPayload(
        token: String,
        keypair: Keypair,
        action: ANSPayload.Action
    ) -> EncodedPayload? {
        let payload = ANSPayload(token: token, provider: ansProvider, action: action)

        guard
            let data = try? JSONEncoder().encode(payload),
            let payload = String(data: data, encoding: .utf8),
            let encodedPayload = adamantCore.encodeMessage(
                payload,
                recipientPublicKey: AdamantResources.contacts.ansPublicKey,
                privateKey: keypair.privateKey
            )
        else { return nil }

        return encodedPayload
    }

    @discardableResult
    fileprivate func sendMessageToANS(
        keypair: Keypair,
        encodedPayload: EncodedPayload,
        completion: @escaping @Sendable (_ success: Bool) -> Void
    ) -> UnregisteredTransaction? {
        guard
            let messageTransaction = try? adamantCore.makeSendMessageTransaction(
                senderId: AdamantUtilities.generateAddress(publicKey: keypair.publicKey),
                recipientId: AdamantResources.contacts.ansAddress,
                keypair: keypair,
                message: encodedPayload.message,
                type: ChatType.signal,
                nonce: encodedPayload.nonce,
                amount: nil,
                date: AdmWalletService.correctedDate
            )
        else { return nil }

        Task {
            switch await apiService.sendMessageTransaction(transaction: messageTransaction) {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }

        return messageTransaction
    }
}

// MARK: - SecureStore

extension AdamantPushNotificationsTokenService {
    fileprivate func setTokenToStorage(_ token: String?) {
        SecureStoreSemaphore.wait()
        defer { SecureStoreSemaphore.signal() }

        if let token = token {
            SecureStore.set(token, for: StoreKey.PushNotificationsTokenService.token)
        } else {
            SecureStore.remove(StoreKey.PushNotificationsTokenService.token)
        }
    }

    fileprivate func getToken() -> String? {
        SecureStore.get(StoreKey.PushNotificationsTokenService.token)
    }

    fileprivate func addTokenDeletionTransaction(_ transaction: UnregisteredTransaction) {
        SecureStoreSemaphore.wait()
        defer { SecureStoreSemaphore.signal() }

        var transactions = getTokenDeletionTransactions()
        transactions.insert(transaction)
        SecureStore.set(transactions, for: StoreKey.PushNotificationsTokenService.tokenDeletionTransactions)
    }

    fileprivate func removeTokenDeletionTransaction(_ transaction: UnregisteredTransaction) {
        SecureStoreSemaphore.wait()
        defer { SecureStoreSemaphore.signal() }

        var transactions = getTokenDeletionTransactions()
        transactions.remove(transaction)
        SecureStore.set(transactions, for: StoreKey.PushNotificationsTokenService.tokenDeletionTransactions)
    }

    fileprivate func getTokenDeletionTransactions() -> Set<UnregisteredTransaction> {
        SecureStore.get(StoreKey.PushNotificationsTokenService.tokenDeletionTransactions) ?? .init()
    }
}
