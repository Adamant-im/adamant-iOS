//
//  WalletCollectionViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FreakingSimpleRoundImageView
import Parchment
import CommonKit

class WalletCollectionViewCell: PagingCell {
    @IBOutlet weak var currencyImageView: UIImageView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var currencySymbolLabel: UILabel!
    @IBOutlet weak var accessoryContainerView: AccessoryContainerView!
    
    override func setPagingItem(_ pagingItem: PagingItem, selected: Bool, options: PagingOptions) {
        guard let item = pagingItem as? WalletPagingItem else {
            return
        }
        
        currencyImageView.image = item.currencyImage
        if item.currencyNetwork.isEmpty {
            currencySymbolLabel.text = item.currencySymbol
        } else {
            let currencyFont = currencySymbolLabel.font ?? .systemFont(ofSize: 12)
            let networkFont = currencyFont.withSize(8)
            let currencyAttributes: [NSAttributedString.Key: Any] = [.font: currencyFont]
            let networkAttributes: [NSAttributedString.Key: Any] = [.font: networkFont]
          
            let defaultString = NSMutableAttributedString(string: item.currencySymbol, attributes: currencyAttributes)
            let underlineString = NSAttributedString(string: " \(item.currencyNetwork)", attributes: networkAttributes)
            defaultString.append(underlineString)
            currencySymbolLabel.attributedText = defaultString
        }
        
        if let balance = item.balance, item.isBalanceInitialized {
            if balance < 1 {
                balanceLabel.text = stringFor(balance: balance)
            } else {
                balanceLabel.text = AdamantBalanceFormat.short.format(balance)
            }
        } else {
            balanceLabel.text = String.adamant.account.updatingBalance
        }
        
        if item.notifications > 0 {
            accessoryContainerView.setAccessory(AccessoryType.label(text: String(item.notifications)), at: .topRight)
        } else {
            accessoryContainerView.setAccessory(nil, at: .topRight)
        }
    }
    
    private func stringFor(balance: Decimal) -> String {
        let significantDigits = 5
        let balanceStr = String(describing: balance)
        
        let minBalance: Decimal = Decimal(pow(10, -(Double(significantDigits - 1))))
        
        // Check if the number has a decimal part
        if balanceStr.contains(".") {
            let parts = balanceStr.split(separator: ".")
            guard let wholePart = parts.first,
                  let decimal = parts.last
            else {
                return AdamantBalanceFormat.compact.format(balance)
            }
            
            let decimalPart = String(decimal)
            
            if balance < minBalance {
                return "0.00…\(decimalPart.last ?? "0")"
            }
            
            if balance > 1_000_000 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 1
                formatter.roundingMode = .down
                
                var whole: Double = minBalance.doubleValue
                whole.round(.towardZero)
                
                var wholeString: String = ""
                
                if whole >= 1_000_000_000_000_000 {
                    wholeString = "\(formatter.string(for: whole / 1_000_000_000_000_000) ?? "")Q"
                } else if whole >= 1_000_000_000_000 {
                    wholeString = "\(formatter.string(for: whole / 1_000_000_000_000) ?? "")T"
                } else if whole >= 1_000_000_000 {
                    wholeString = "\(formatter.string(for: whole / 1_000_000_000) ?? "")B"
                } else {
                    wholeString = "\(formatter.string(for: whole / 1_000_000) ?? "")M"
                }
                return wholeString
            }
            
            let additionalDigits = significantDigits - wholePart.count
            
            guard additionalDigits > .zero else { return String(wholePart) }
            
            var formattedDecimal = ""
            
            for digit in decimalPart.prefix(additionalDigits) {
                formattedDecimal.append(digit)
            }
            
            var value = "\(wholePart).\(formattedDecimal)"
            return value
            
        } else {
            var value = AdamantBalanceFormat.compact.format(balance)
            return "\(value)"
        }
    }
}
