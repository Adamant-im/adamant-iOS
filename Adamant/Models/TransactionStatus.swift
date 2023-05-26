//
//  TransactionStatus.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

enum TransactionStatus: Int16 {
    case notInitiated
    case pending
    case success
    case failed
    case registered
    case inconsistent
    case noNetwork
    case noNetworkFinal
    
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
        case .noNetwork, .noNetworkFinal:
            return NSLocalizedString("Error.NoNetwork", comment: "Shared error: Network problems. In most cases - no connection")
        }
    }
    
    var color: UIColor {
        switch self {
        case .failed: return .adamant.danger
        case .notInitiated, .inconsistent, .noNetwork, .noNetworkFinal, .pending, .registered: return .adamant.alert
        case .success: return .adamant.good
        }
    }
    
    var descriptionLocalized: String? {
        switch self {
        case .inconsistent:
            return NSLocalizedString("TransactionStatus.Inconsistent.WrongTimestamp", comment: "Transaction status: inconsistent wrong timestamp")
        default:
            return nil
        }
    }
}
