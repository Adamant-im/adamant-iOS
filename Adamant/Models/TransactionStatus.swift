//
//  TransactionStatus.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum TransactionStatus: Int16 {
    case notInitiated
    case pending
    case success
    case failed
    case registered
    case inconsistent
    case noNetwork
    
    var localized: String {
        switch self {
        case .notInitiated:
            return NSLocalizedString("TransactionStatus.Updating", comment: "Transaction status: updating in progress")
        case .pending, .registered:
            return NSLocalizedString("TransactionStatus.Pending", comment: "Transaction status: transaction is pending")
        case .success:
            return NSLocalizedString("TransactionStatus.Success", comment: "Transaction status: success")
        case .failed:
            return NSLocalizedString("TransactionStatus.Failed", comment: "Transaction status: transaction failed")
        case .inconsistent:
            return NSLocalizedString("TransactionStatus.Inconsistent", comment: "Transaction status: transaction warning")
        case .noNetwork:
            return NSLocalizedString("Error.NoNetwork", comment: "Shared error: Network problems. In most cases - no connection")
        }
    }
}
