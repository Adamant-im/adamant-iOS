//
//  DogeWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 13/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit
import CommonKit

extension DogeWalletService: RichMessageProvider {
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
            return NSAttributedString(string: "⬅️  \(DogeWalletService.currencySymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(DogeWalletService.currencySymbol)"
        } else {
            string = "➡️  \(amount) \(DogeWalletService.currencySymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
