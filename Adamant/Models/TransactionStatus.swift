//
//  TransactionStatus.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

enum InconsistentReason: Codable, Hashable {
    case time
    case duplicate
    case unknown
    case wrongTxHash
    case wrongAmount
    case senderCryptoAddressMismatch(String)
    case recipientCryptoAddressMismatch(String)
    case senderCryptoAddressUnavailable(String)
    case recipientCryptoAddressUnavailable(String)
    
    var localized: String {
        switch self {
        case .time:
            return .localized("TransactionStatus.Inconsistent.WrongTimestamp", comment: "Transaction status: inconsistent wrong timestamp")
        case .duplicate:
            return .localized("TransactionStatus.Inconsistent.Duplicate", comment: "Transaction status: inconsistent duplicate")
        case .unknown:
            return .localized("TransactionStatus.Inconsistent.Unknown", comment: "Transaction status: inconsistent wrong unknown")
        case .wrongTxHash:
            return .localized("TransactionStatus.Inconsistent.WrongTxHash", comment: "Transaction status: inconsistent wrong hash")
        case .wrongAmount:
            return .localized("TransactionStatus.Inconsistent.WrongAmount", comment: "Transaction status: inconsistent wrong amount")
        case .senderCryptoAddressMismatch(let coin):
            return String.localizedStringWithFormat(.localized("TransactionStatus.Inconsistent.SenderCryptoAddressMismatch", comment: "Transaction status: inconsistent wrong mismatch"), coin)
        case .recipientCryptoAddressMismatch(let coin):
            return String.localizedStringWithFormat(.localized("TransactionStatus.Inconsistent.RecipientCryptoAddressMismatch", comment: "Transaction status: inconsistent wrong mismatch"), coin)
        case .senderCryptoAddressUnavailable(let coin):
            return String.localizedStringWithFormat(.localized("TransactionStatus.Inconsistent.SenderCryptoAddressUnavailable", comment: "Transaction status: inconsistent unable to retrieve"), coin)
        case .recipientCryptoAddressUnavailable(let coin):
            return String.localizedStringWithFormat(.localized("TransactionStatus.Inconsistent.RecipientCryptoAddressUnavailable", comment: "Transaction status: inconsistent unable to retrieve"), coin)
        }
    }
}

enum TransactionStatus: Codable, Equatable, Hashable {
    case notInitiated
    case pending
    case success
    case failed
    case registered
    case inconsistent(InconsistentReason)
    
    var localized: String {
        switch self {
        case .notInitiated:
            return "⏱"
        case .pending, .registered:
            return .localized("TransactionStatus.Pending", comment: "Transaction status: transaction is pending")
        case .success:
            return .localized("TransactionStatus.Success", comment: "Transaction status: success")
        case .failed:
            return .localized("TransactionStatus.Failed", comment: "Transaction status: transaction failed")
        case .inconsistent:
            return .localized("TransactionStatus.Inconsistent", comment: "Transaction status: transaction warning")
        }
    }
}

extension TransactionStatus {
    var isInconsistent: Bool {
        if case .inconsistent = self {
            return true
        }
        
        return false
    }
}
