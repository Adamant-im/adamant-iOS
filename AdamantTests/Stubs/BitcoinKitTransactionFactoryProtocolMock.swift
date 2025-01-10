//
//  BitcoinKitTransactionFactoryProtocolMock.swift
//  Adamant
//
//  Created by Christian Benua on 11.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import BitcoinKit

final class BitcoinKitTransactionFactoryProtocolMock: BitcoinKitTransactionFactoryProtocol {
    
    var invokedCreateTransaction: Bool = false
    var invokedCreateTransactionCount: Int = 0
    var invokedCreateTransactionParameters: (
        toAddress: Address,
        amount: UInt64,
        fee: UInt64,
        changeAddress: Address,
        utxos: [UnspentTransaction],
        lockTime: UInt32,
        keys: [PrivateKey]
    )?
    var stubbedTransactionFactory: ((
        _ toAddress: Address,
        _ amount: UInt64,
        _ fee: UInt64,
        _ changeAddress: Address,
        _ utxos: [UnspentTransaction],
        _ lockTime: UInt32,
        _ keys: [PrivateKey]
    ) -> Transaction)?
    
    func createTransaction(
        toAddress: Address,
        amount: UInt64,
        fee: UInt64,
        changeAddress: Address,
        utxos: [UnspentTransaction],
        lockTime: UInt32,
        keys: [PrivateKey]
    ) -> Transaction {
        invokedCreateTransaction = true
        invokedCreateTransactionCount += 1
        invokedCreateTransactionParameters = (
            toAddress,
            amount,
            fee,
            changeAddress,
            utxos,
            lockTime,
            keys
        )
        
        return stubbedTransactionFactory!(
            toAddress,
            amount,
            fee,
            changeAddress,
            utxos,
            lockTime,
            keys
        )
    }
}
