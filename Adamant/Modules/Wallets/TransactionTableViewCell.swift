//
//  TransactionTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit

final class TransactionTableViewCell: UITableViewCell {
    enum TransactionType {
        case income, outcome, myself
        
        var imageTop: UIImage {
            switch self {
            case .income: return .asset(named: "transfer-in_top") ?? .init()
            case .outcome: return .asset(named: "transfer-out_top") ?? .init()
            case .myself: return .asset(named: "transfer-in_top")?.withTintColor(.lightGray) ?? .init()
            }
        }
        
        var imageBottom: UIImage {
            switch self {
            case .income: return .asset(named: "transfer-in_bot") ?? .init()
            case .outcome: return .asset(named: "transfer-out_bot") ?? .init()
            case .myself: return .asset(named: "transfer-self_bot") ?? .init()
            }
        }
        
        var bottomTintColor: UIColor {
            switch self {
            case .income: return UIColor.adamant.transferIncomeIconBackground
            case .outcome: return UIColor.adamant.transferOutcomeIconBackground
            case .myself: return UIColor.adamant.transferIncomeIconBackground
            }
        }
    }
    
    // MARK: - Constants
    
    static let cellHeightCompact: CGFloat = 90.0
    static let cellFooterLoadingCompact: CGFloat = 30.0
    static let cellHeightFull: CGFloat = 100.0
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var bottomImageView: UIImageView!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var ammountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    // MARK: - Properties
    
    var transactionType: TransactionType = .income {
        didSet {
            topImageView.image = transactionType.imageTop
            bottomImageView.image = transactionType.imageBottom
            bottomImageView.tintColor = transactionType.bottomTintColor
        }
    }
    
    var currencySymbol: String?
    
    var transaction: SimpleTransactionDetails? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - Initializers
    
    override func awakeFromNib() {
        transactionType = .income
    }
    
    func updateUI() {
        guard let transaction = transaction else { return }
        
        let partnerId = transaction.isOutgoing
        ? transaction.recipientAddress
        : transaction.senderAddress
        
        let transactionType: TransactionTableViewCell.TransactionType
        if transaction.recipientAddress == transaction.senderAddress {
            transactionType = .myself
        } else if transaction.isOutgoing {
            transactionType = .outcome
        } else {
            transactionType = .income
        }
        
        self.transactionType = transactionType
        
        backgroundColor = .clear
        accountLabel.tintColor = UIColor.adamant.primary
        ammountLabel.tintColor = UIColor.adamant.primary
        
        dateLabel.textColor = transaction.transactionStatus?.color ?? .adamant.secondary
        
        switch transaction.transactionStatus {
        case .success, .inconsistent:
            if let date = transaction.dateValue {
                dateLabel.text = date.humanizedDateTime()
            } else {
                dateLabel.text = nil
            }
        case .notInitiated:
            dateLabel.text = TransactionDetailsViewControllerBase.awaitingValueString
        case .failed:
            dateLabel.text = TransactionStatus.failed.localized
        default:
            dateLabel.text = TransactionStatus.pending.localized
        }
        
        if let partnerName = transaction.partnerName {
            accountLabel.text = partnerName
            addressLabel.text = partnerId
            addressLabel.lineBreakMode = .byTruncatingMiddle
            
            if addressLabel.isHidden {
                addressLabel.isHidden = false
            }
        } else {
            accountLabel.text = partnerId
            
            if !addressLabel.isHidden {
                addressLabel.isHidden = true
            }
        }
        
        let amount = transaction.amountValue ?? .zero
        ammountLabel.text = AdamantBalanceFormat.full.format(amount, withCurrencySymbol: currencySymbol)
    }
}

// MARK: - TransactionStatus UI
private extension TransactionStatus {
    var color: UIColor {
        switch self {
        case .failed:
            return .adamant.danger
        case .noNetwork, .noNetworkFinal, .pending, .registered:
            return .adamant.alert
        case .success, .inconsistent, .notInitiated:
            return .adamant.secondary
        }
    }
}
