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
    case updating
    case pending
    case success
    case failed
    case warning
    case dublicate
    
    var localized: String {
        switch self {
        case .notInitiated, .updating:
            return NSLocalizedString("TransactionStatus.Updating", comment: "Transaction status: updating in progress")
        case .pending:
            return NSLocalizedString("TransactionStatus.Pending", comment: "Transaction status: transaction is pending")
        case .success:
            return NSLocalizedString("TransactionStatus.Success", comment: "Transaction status: success")
        case .failed:
            return NSLocalizedString("TransactionStatus.Failed", comment: "Transaction status: transaction failed")
        case .warning, .dublicate:
            return NSLocalizedString("TransactionStatus.Warning", comment: "Transaction status: transaction warning")
        }
    }
    
    var isFinal: Bool {
        switch self {
        case .notInitiated, .updating, .pending:
            return false
        case .dublicate, .warning, .failed, .success:
            return true
        }
    }
}
