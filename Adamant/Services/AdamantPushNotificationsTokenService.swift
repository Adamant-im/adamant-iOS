//
//  AdamantPushNotificationsTokenService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class AdamantPushNotificationsTokenService: PushNotificationsTokenService {
    private let securedStore: SecuredStore
    private let apiService: ApiService
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    
    private let tokenProcessingQueue = DispatchQueue(label: "com.adamant.push-token-processing-queue")
    private let tokenProcessingSemaphore = DispatchSemaphore(value: 1)
    private let securedStoreSemaphore = DispatchSemaphore(value: 1)
    
    init(
        securedStore: SecuredStore,
        apiService: ApiService,
        adamantCore: AdamantCore,
        accountService: AccountService
    ) {
        self.securedStore = securedStore
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
                await apiService.sendTransaction(
                    path: AdamantApiService.ApiCommands.Chats.processTransaction,
                    transaction: transaction
                ) { [weak self] result in
                    switch result {
                    case .success, .failure(.accountNotFound), .failure(.notLogged):
                        self?.removeTokenDeletionTransaction(transaction)
                    case .failure(.internalError), .failure(.networkError), .failure(.requestCancelled), .failure(.serverError), .failure(.commonError):
                        break
                    }
                }
            }
        }
    }
}

private extension AdamantPushNotificationsTokenService {
    typealias EncodedPayload = (message: String, nonce: String)
    
    var ansProvider: ANSPayload.Provider {
        #if DEBUG
        return .apnsSandbox
        #else
        return .apns
        #endif
    }
    
    func _setToken(_ token: Data) {
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
    
    func _removeCurrentToken() {
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
    
    func mapToken(_ token: Data) -> String {
        token.map { String(format: "%02.2hhx", $0) }.joined()
    }
    
    func updateCurrentToken(newToken: String, keypair: Keypair, completion: @escaping () -> Void) {
        guard let encodedPayload = makeEncodedPayload(token: newToken, keypair: keypair, action: .add) else {
            return completion()
        }
        
        removeCurrentToken(keypair: keypair) {
            Task { [weak self] in
                await self?.sendMessageToANS(
                    keypair: keypair,
                    encodedPayload: encodedPayload
                ) { success in
                    defer { completion() }
                    guard success else { return }
                    self?.setTokenToStorage(newToken)
                }
            }
        }
    }
    
    func removeCurrentToken(keypair: Keypair, completion: @escaping () -> Void) {
        guard
            let token = getToken(),
            let encodedPayload = makeEncodedPayload(
                token: token,
                keypair: keypair,
                action: .remove
            )
        else { return completion() }
        
        setTokenToStorage(nil)
        
        Task {
            var transaction: UnregisteredTransaction?
            
            transaction = await sendMessageToANS(
                keypair: keypair,
                encodedPayload: encodedPayload
            ) { [weak self] success in
                defer { completion() }
                guard !success, let self = self, let transaction = transaction else { return }
                self.addTokenDeletionTransaction(transaction)
            }
        }
    }
    
    func makeEncodedPayload(
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
    func sendMessageToANS(
        keypair: Keypair,
        encodedPayload: EncodedPayload,
        completion: @escaping (_ success: Bool) -> Void
    ) async -> UnregisteredTransaction? {
        await apiService.sendMessage(
            senderId: AdamantUtilities.generateAddress(publicKey: keypair.publicKey),
            recipientId: AdamantResources.contacts.ansAddress,
            keypair: keypair,
            message: encodedPayload.message,
            type: ChatType.signal,
            nonce: encodedPayload.nonce,
            amount: nil
        ) { result in
            switch result {
            case .success:
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
}

// MARK: - SecuredStore

private extension AdamantPushNotificationsTokenService {
    func setTokenToStorage(_ token: String?) {
        securedStoreSemaphore.wait()
        defer { securedStoreSemaphore.signal() }
        
        if let token = token {
            securedStore.set(token, for: StoreKey.PushNotificationsTokenService.token)
        } else {
            securedStore.remove(StoreKey.PushNotificationsTokenService.token)
        }
    }
    
    func getToken() -> String? {
        securedStore.get(StoreKey.PushNotificationsTokenService.token)
    }
    
    func addTokenDeletionTransaction(_ transaction: UnregisteredTransaction) {
        securedStoreSemaphore.wait()
        defer { securedStoreSemaphore.signal() }
        
        var transactions = getTokenDeletionTransactions()
        transactions.insert(transaction)
        securedStore.set(transactions, for: StoreKey.PushNotificationsTokenService.tokenDeletionTransactions)
    }
    
    func removeTokenDeletionTransaction(_ transaction: UnregisteredTransaction) {
        securedStoreSemaphore.wait()
        defer { securedStoreSemaphore.signal() }
        
        var transactions = getTokenDeletionTransactions()
        transactions.remove(transaction)
        securedStore.set(transactions, for: StoreKey.PushNotificationsTokenService.tokenDeletionTransactions)
    }
    
    func getTokenDeletionTransactions() -> Set<UnregisteredTransaction> {
        securedStore.get(StoreKey.PushNotificationsTokenService.tokenDeletionTransactions) ?? .init()
    }
}
