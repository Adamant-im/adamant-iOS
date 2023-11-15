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
