//
//  BtcWalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 20/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit
import CommonKit

extension BtcWalletService {
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
            return NSAttributedString(string: "⬅️  \(BtcWalletService.currencySymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(BtcWalletService.currencySymbol)"
        } else {
            string = "➡️  \(amount) \(BtcWalletService.currencySymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
