//
//  AdmWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit
import CommonKit

extension AdmWalletService: RichMessageProvider {
    var newPendingInterval: TimeInterval {
        .zero
    }
    
    var oldPendingInterval: TimeInterval {
        .zero
    }
    
    var registeredInterval: TimeInterval {
        .zero
    }
    
    var newPendingAttempts: Int {
        .zero
    }
    
    var oldPendingAttempts: Int {
        .zero
    }
    
    var dynamicRichMessageType: String {
        return type(of: self).richMessageType
    }
    
    // MARK: Events
    
    func richMessageTapped(for transaction: RichMessageTransaction, in chat: ChatViewController) {
        return
    }
    
    // MARK: Short description
    private static var formatter: NumberFormatter = {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: currencySymbol)
    }()
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        guard let balance = transaction.amount as Decimal? else {
            return NSAttributedString(string: "")
        }
        
        return NSAttributedString(string: shortDescription(isOutgoing: transaction.isOutgoing, balance: balance))
    }
    
    /// For ADM transfers
    func shortDescription(for transaction: TransferTransaction) -> String {
        guard let balance = transaction.amount as Decimal? else {
            return ""
        }
        
        return shortDescription(isOutgoing: transaction.isOutgoing, balance: balance)
    }
    
    private func shortDescription(isOutgoing: Bool, balance: Decimal) -> String {
        if isOutgoing {
            return "⬅️  \(AdmWalletService.formatter.string(from: balance)!)"
        } else {
            return "➡️  \(AdmWalletService.formatter.string(from: balance)!)"
        }
    }
}

// MARK: - Tools
extension MessageStatus {
    func toTransactionStatus() -> TransactionStatus {
        switch self {
        case .pending: return TransactionStatus.pending
        case .delivered: return TransactionStatus.success
        case .failed: return TransactionStatus.failed
        }
    }
}
