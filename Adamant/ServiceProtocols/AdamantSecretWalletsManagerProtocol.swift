//
//  AdamantSecretWalletsManagerProtocol.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 19.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

protocol AdamantSecretWalletsManagerProtocol {
    var statePublisher: AnyObservable<AdamantSecretWalletsManager.State> { get }
        
    /// Adds new secret wallet and activates it
    func createSecretWallet(withPassword password: String)
    func removeSecretWallet(at index: Int) -> WalletStoreServiceProtocol?
    func getCurrentWallet() -> WalletStoreServiceProtocol
    func activateSecretWallet(at index: Int)
    func activateDefaultWallet()
    func getWallets() -> [WalletStoreServiceProtocol]
}
