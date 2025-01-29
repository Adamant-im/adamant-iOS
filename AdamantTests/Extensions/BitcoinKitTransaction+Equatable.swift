//
//  BitcoinKitTransaction+Equatable.swift
//  Adamant
//
//  Created by Christian Benua on 10.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import BitcoinKit

extension BitcoinKit.Transaction: Equatable {
    public static func == (lhs: BitcoinKit.Transaction, rhs: BitcoinKit.Transaction) -> Bool {
        lhs.version == rhs.version &&
        lhs.inputs == rhs.inputs &&
        lhs.outputs == rhs.outputs &&
        lhs.lockTime == rhs.lockTime
    }
}

extension BitcoinKit.TransactionInput: Equatable {
    public static func == (lhs: BitcoinKit.TransactionInput, rhs: BitcoinKit.TransactionInput) -> Bool {
        lhs.previousOutput == rhs.previousOutput &&
        lhs.signatureScript == rhs.signatureScript &&
        lhs.sequence == rhs.sequence
    }
}

extension BitcoinKit.TransactionOutPoint: Equatable {
    public static func == (lhs: BitcoinKit.TransactionOutPoint, rhs: BitcoinKit.TransactionOutPoint) -> Bool {
        lhs.hash == rhs.hash &&
        lhs.index == rhs.index
    }
}

extension BitcoinKit.TransactionOutput: Equatable {
    public static func == (lhs: BitcoinKit.TransactionOutput, rhs: BitcoinKit.TransactionOutput) -> Bool {
        lhs.value == rhs.value &&
        lhs.lockingScript == rhs.lockingScript
    }
}
