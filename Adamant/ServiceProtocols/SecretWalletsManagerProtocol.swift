//
//  SecretWalletsManagerProtocol.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 19.02.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit

protocol SecretWalletsManagerProtocol {
    var statePublisher: ObservableSender<SecretWalletsManagerStateProtocol> { get }
        
    func createSecretWallet(withPassword password: String)
    func removeSecretWallet(at index: Int) -> WalletStoreServiceProtocol?
    func getCurrentWallet() -> WalletStoreServiceProtocol
    func getSecretWallets() -> [WalletStoreServiceProtocol]
    func activateSecretWallet(at index: Int)
    func activateDefaultWallet()
}

protocol SecretWalletsManagerStateProtocol {
    var currentWallet: WalletStoreServiceProtocol { get set }
    var regularWallet: WalletStoreServiceProtocol { get set }
    var secretWallets: [WalletStoreServiceProtocol] { get set }
}
