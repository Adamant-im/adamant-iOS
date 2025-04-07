//
//  WalletServiceError+Equatable.swift
//  Adamant
//
//  Created by Christian Benua on 10.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant

extension WalletServiceError: Equatable {
    public static func == (lhs: Adamant.WalletServiceError, rhs: Adamant.WalletServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.notLogged, .notLogged), (.notEnoughMoney, .notEnoughMoney), (.networkError, .networkError),
            (.accountNotFound, .accountNotFound), (.walletNotInitiated, .walletNotInitiated),
            (.requestCancelled, .requestCancelled), (.dustAmountError, .dustAmountError):
            return true
        case let (.invalidAmount(lhsValue), invalidAmount(rhsValue)):
            return lhsValue == rhsValue
        case let (.transactionNotFound(lhsValue), transactionNotFound(rhsValue)):
            return lhsValue == rhsValue
        case (.apiError, .apiError):
            return true
        case let (.remoteServiceError(lhsValue, _), .remoteServiceError(rhsValue, _)):
            return lhsValue == rhsValue
        case let (.internalError(lhsValue, _), .internalError(rhsValue, _)):
            return lhsValue == rhsValue
        case (.notLogged, _), (.notEnoughMoney, _), (.networkError, _), (.accountNotFound, _), (.walletNotInitiated, _),
            (.requestCancelled, _), (.dustAmountError, _), (.invalidAmount, _), (.transactionNotFound, _),
            (.apiError, _), (.remoteServiceError, _), (.internalError, _):
            return false
        }
    }
}
