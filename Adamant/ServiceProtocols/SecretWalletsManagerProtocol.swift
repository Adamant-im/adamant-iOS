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
    var currentWalletIndex: Int { get }
        
    func createSecretWallet(withPassword password: String)
    func removeSecretWallet(at index: Int) -> WalletStoreServiceProtocol?
    func getCurrentWallet() -> WalletStoreServiceProtocol
    func getSecretWallets() -> [WalletStoreServiceProtocol]
    func activateWallet(at index: Int)
}

protocol SecretWalletsManagerStateProtocol {
    var currentWallet: WalletStoreServiceProtocol { get set }
    var wallets: [WalletStoreServiceProtocol] { get set }
}
