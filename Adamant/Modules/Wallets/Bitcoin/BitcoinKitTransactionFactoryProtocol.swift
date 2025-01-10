//
//  BitcoinKitTransactionFactoryProtocol.swift
//  Adamant
//
//  Created by Christian Benua on 11.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import BitcoinKit

protocol BitcoinKitTransactionFactoryProtocol {
    func createTransaction(
        toAddress: Address,
        amount: UInt64,
        fee: UInt64,
        changeAddress: Address,
        utxos: [UnspentTransaction],
        lockTime: UInt32,
        keys: [PrivateKey]
    ) -> Transaction
}

final class BitcoinKitTransactionFactory: BitcoinKitTransactionFactoryProtocol {
    func createTransaction(
        toAddress address: Address,
        amount: UInt64,
        fee: UInt64,
        changeAddress: Address,
        utxos: [UnspentTransaction],
        lockTime: UInt32,
        keys: [PrivateKey]
    ) -> Transaction {
        BitcoinKit.Transaction.createNewTransaction(
            toAddress: address,
            amount: amount,
            fee: fee,
            changeAddress: changeAddress,
            utxos: utxos,
            lockTime: lockTime,
            keys: keys
        )
    }
}
