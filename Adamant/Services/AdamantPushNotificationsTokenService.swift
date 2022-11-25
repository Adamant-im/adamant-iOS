//
//  AdamantPushNotificationsTokenService.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

final class AdamantPushNotificationsTokenService: PushNotificationsTokenService {
    private let securedStore: SecuredStore
    private let apiService: ApiService
    private let adamantCore: AdamantCore
    private let accountService: AccountService
    
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
        guard let keypair = accountService.keypair else {
            assertionFailure("Trying to register with no user logged")
            return
        }
        
        let token = mapToken(token)
        print("APNS token:", token)
        
        guard token != getToken() else { return }
        updateCurrentToken(newToken: token, keypair: keypair)
    }
    
    func removeCurrentToken() {
        guard let keypair = accountService.keypair else {
            assertionFailure("Trying to unregister with no user logged")
            return
        }
        
        removeCurrentToken(keypair: keypair)
    }
    
    func sendTokenDeletionTransactions() {
        for transaction in getTokenDeletionTransactions() {
            apiService.sendTransaction(
                path: AdamantApiService.ApiCommands.Chats.processTransaction,
                transaction: transaction
            ) { [weak self] result in
                switch result {
                case .success, .failure(.accountNotFound), .failure(.notLogged):
                    self?.removeTokenDeletionTransaction(transaction)
                case .failure(.internalError), .failure(.networkError), .failure(.requestCancelled), .failure(.serverError):
                    break
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
    
    func mapToken(_ token: Data) -> String {
        token.map { String(format: "%02.2hhx", $0) }.joined()
    }
    
    func updateCurrentToken(newToken: String, keypair: Keypair) {
        guard let encodedPayload = makeEncodedPayload(token: newToken, keypair: keypair, action: .add) else {
            return
        }
        
        sendMessageToANS(keypair: keypair, encodedPayload: encodedPayload) { [weak self] success in
            guard success, let self = self else { return }
            self.removeCurrentToken(keypair: keypair)
            self.setToken(newToken)
        }
    }
    
    func removeCurrentToken(keypair: Keypair) {
        guard
            let token = getToken(),
            let encodedPayload = makeEncodedPayload(
                token: token,
                keypair: keypair,
                action: .remove
            )
        else { return }
        
        var transaction: UnregisteredTransaction?
        transaction = sendMessageToANS(keypair: keypair, encodedPayload: encodedPayload) { [weak self] success in
            guard !success, let self = self, let transaction = transaction else { return }
            self.addTokenDeletionTransaction(transaction)
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
    ) -> UnregisteredTransaction? {
        apiService.sendMessage(
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
    func setToken(_ token: String) {
        securedStore.set(token, for: StoreKey.PushNotificationsTokenService.token)
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
