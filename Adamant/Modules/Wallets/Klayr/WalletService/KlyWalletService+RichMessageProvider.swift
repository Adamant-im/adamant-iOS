//
//  KlyWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import LiskKit
import CommonKit

extension KlyWalletService {
    var newPendingInterval: TimeInterval {
        .init(milliseconds: type(of: self).newPendingInterval)
    }
    
    var oldPendingInterval: TimeInterval {
        .init(milliseconds: type(of: self).oldPendingInterval)
    }
    
    var registeredInterval: TimeInterval {
        .init(milliseconds: type(of: self).registeredInterval)
    }
    
    var newPendingAttempts: Int {
        type(of: self).newPendingAttempts
    }
    
    var oldPendingAttempts: Int {
        type(of: self).oldPendingAttempts
    }
    
    var dynamicRichMessageType: String {
        return type(of: self).richMessageType
    }
    
    // MARK: Short description
    
    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount)
        else {
            return NSAttributedString(string: "⬅️  \(KlyWalletService.currencySymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(KlyWalletService.currencySymbol)"
        } else {
            string = "➡️  \(amount) \(KlyWalletService.currencySymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
