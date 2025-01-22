//
//  SecretWalletsService.swift
//  Adamant
//
//  Created by Dmitrij Meidus on 22.01.25.
//  Copyright © 2025 Adamant. All rights reserved.
//

protocol SecretWalletsService {
    var publicWallet: PublicWalletServiceCompose { get }
    var secretWallets: [String: SecretWalletServiceCompose] { get }
    var currentWallet: PublicWalletServiceCompose { get }
}

final class AdamantSecretWalletsService: SecretWalletsService {
    private(set) var publicWallet: PublicWalletServiceCompose
    private(set) var secretWallets: [String: SecretWalletServiceCompose]
    private(set) var currentWallet: PublicWalletServiceCompose
    
    init(publicWallet: PublicWalletServiceCompose, secretWallets: [String: SecretWalletServiceCompose]) {
        self.publicWallet = publicWallet
        self.secretWallets = secretWallets
        self.currentWallet = publicWallet
    }
}
