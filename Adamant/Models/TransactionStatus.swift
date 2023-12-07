//
//  TransactionStatus.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

enum InconsistentReason: Int16 {
    case time = 8
    case duplicate = 9
    case unknown = 10
    case wrongTxHash = 11
    case wrongAmount = 12
    case senderCryptoAddressMismatch = 13
    case recipientCryptoAddressMismatch = 14
    
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
        case .senderCryptoAddressMismatch:
            return .localized("TransactionStatus.Inconsistent.SenderCryptoAddressMismatch", comment: "Transaction status: inconsistent wrong mismatch")
        case .recipientCryptoAddressMismatch:
            return .localized("TransactionStatus.Inconsistent.RecipientCryptoAddressMismatch", comment: "Transaction status: inconsistent wrong mismatch")
        }
    }
}

enum TransactionStatus: RawRepresentable, Equatable, Hashable {
    case notInitiated
    case pending
    case success
    case failed
    case registered
    case inconsistent(InconsistentReason)
    case noNetwork
    case noNetworkFinal
    
    typealias RawValue = Int16
    
    var rawValue: RawValue {
        switch self {
        case .notInitiated: return 0
        case .pending: return 1
        case .success: return 2
        case .failed: return 3
        case .registered: return 4
        case .inconsistent(let reason): return reason.rawValue
        case .noNetwork: return 6
        case .noNetworkFinal: return 7
        }
    }
    
    init?(rawValue: RawValue) {
        switch rawValue {
        case 0: self = .notInitiated
        case 1: self = .pending
        case 2: self = .success
        case 3: self = .failed
        case 4: self = .registered
        case 6: self = .noNetwork
        case 7: self = .noNetworkFinal
        default:
            if let reason = InconsistentReason(rawValue: rawValue) {
                self = .inconsistent(reason)
            } else {
                return nil
            }
        }
    }
    
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
        case .noNetwork, .noNetworkFinal:
            return .localized("Error.NoNetwork", comment: "Shared error: Network problems. In most cases - no connection")
        }
    }
}
