//
//  ERC20WalletService+RichMessageProvider.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import MessageKit
import UIKit
import CommonKit

extension ERC20WalletService: RichMessageProvider {
    var newPendingInterval: TimeInterval {
        .init(milliseconds: EthWalletService.newPendingInterval)
    }
    
    var oldPendingInterval: TimeInterval {
        .init(milliseconds: EthWalletService.oldPendingInterval)
    }
    
    var registeredInterval: TimeInterval {
        .init(milliseconds: EthWalletService.registeredInterval)
    }
    
    var newPendingAttempts: Int {
        EthWalletService.newPendingAttempts
    }
    
    var oldPendingAttempts: Int {
        EthWalletService.oldPendingAttempts
    }
    
    // MARK: Short description

    func shortDescription(for transaction: RichMessageTransaction) -> NSAttributedString {
        let amount: String
        
        guard let raw = transaction.getRichValue(for: RichContentKeys.transfer.amount)
        else {
            return NSAttributedString(string: "⬅️  \(self.tokenSymbol)")
        }
        
        if let decimal = Decimal(string: raw) {
            amount = AdamantBalanceFormat.full.format(decimal)
        } else {
            amount = raw
        }
        
        let string: String
        if transaction.isOutgoing {
            string = "⬅️  \(amount) \(self.tokenSymbol)"
        } else {
            string = "➡️  \(amount) \(self.tokenSymbol)"
        }
        
        return NSAttributedString(string: string)
    }
}
