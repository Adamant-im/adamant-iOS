//
//  KlyWalletService+WalletCore.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import LiskKit

extension KlyWalletService {
    var wallet: WalletAccount? {
        klyWallet
    }
    
    var tokenSymbol: String {
        Self.currencySymbol
    }
    
    var tokenLogo: UIImage {
        Self.currencyLogo
    }
    
    static var tokenNetworkSymbol: String {
        Self.currencySymbol
    }
    
    var tokenContract: String {
        .empty
    }
    
    var tokenUnicID: String {
        Self.tokenNetworkSymbol + tokenSymbol
    }
    
    var qqPrefix: String {
        Self.qqPrefix
    }
    
    var additionalFee: Decimal {
        0.05
    }
    
    var nodeGroups: [NodeGroup] {
        [.klyNode, .klyService]
    }
    
    var transactionFee: Decimal {
        transactionFeeRaw.asDecimal(exponent: KlyWalletService.currencyExponent)
    }
    
    var richMessageType: String {
        Self.richMessageType
    }
    
    var transactionsPublisher: AnyObservable<[TransactionDetails]> {
        $transactions.eraseToAnyPublisher()
    }
    
    var hasMoreOldTransactionsPublisher: AnyObservable<Bool> {
        $hasMoreOldTransactions.eraseToAnyPublisher()
    }
}

extension KlyWalletService: PrivateKeyGenerator {
    var rowTitle: String {
        tokenName
    }
    
    var rowImage: UIImage? {
        .asset(named: "klayr_wallet_row")
    }
    
    func generatePrivateKeyFor(passphrase: String) -> String? {
        guard AdamantUtilities.validateAdamantPassphrase(passphrase),
              let keypair = try? LiskKit.Crypto.keyPair(
                fromPassphrase: passphrase,
                salt: salt
              )
        else {
            return nil
        }
        
        return keypair.privateKeyString
    }
}
