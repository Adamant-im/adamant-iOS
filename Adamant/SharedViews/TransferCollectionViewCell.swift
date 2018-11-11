//
//  TransferCollectionViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
//import MessageKit

class TransferCollectionViewCell: UICollectionViewCell, ChatCell, TapRecognizerCustomCell {
    @IBOutlet weak var sentLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var currencySymbolLabel: UILabel!
    @IBOutlet weak var currencyLogoImageView: UIImageView!
    @IBOutlet weak var tapForDetailsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var transferContentView: UIView!
    @IBOutlet weak var bubbleView: UIView!
    
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint?
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusLeadingConstraint: NSLayoutConstraint?
    @IBOutlet weak var statusTrailingConstraint: NSLayoutConstraint?
    
    weak var delegate: CustomCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        bubbleView.layer.cornerRadius = 16.0
        bubbleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
    }
    
    // MARK: - Tap
    
    @objc func didTap(sender: UITapGestureRecognizer) {
        delegate?.didTapCustomCell(self)
    }
    
    // MARK: - Status
    var transactionStatus: TransactionStatus? {
        didSet {
            if let status = transactionStatus {
                statusView.isHidden = false
                statusImageView.image = status.image
                statusImageView.tintColor = status.imageTintColor
            } else {
                statusView.isHidden = true
            }
        }
    }
    
    // MARK: - Appearance
    
    var bubbleBackgroundColor: UIColor? {
        get { return bubbleView.backgroundColor }
        set { bubbleView.backgroundColor = newValue }
    }
    
    var isAlignedRight: Bool = false {
        didSet {
            if isAlignedRight {
                // Bubble
                if let leadingConstraint = leadingConstraint {
                    contentView.removeConstraint(leadingConstraint)
                }
                
                if trailingConstraint == nil {
                    let trailing = NSLayoutConstraint(item: contentView,
                                                      attribute: .trailing,
                                                      relatedBy: .equal,
                                                      toItem: transferContentView,
                                                      attribute: .trailing,
                                                      multiplier: 1.0,
                                                      constant: 5.0)
                    contentView.addConstraint(trailing)
                    trailingConstraint = trailing
                }
                
                // Status
                if let statusLeadingConstraint = statusLeadingConstraint {
                    contentView.removeConstraint(statusLeadingConstraint)
                }
                
                if statusTrailingConstraint == nil {
                    let trailing = NSLayoutConstraint(item: transferContentView,
                                                      attribute: .leading,
                                                      relatedBy: .equal,
                                                      toItem: statusView,
                                                      attribute: .trailing,
                                                      multiplier: 1.0,
                                                      constant: 12.0)
                    contentView.addConstraint(trailing)
                    statusTrailingConstraint = trailing
                }
            } else {
                // Bubble
                if let trailingConstraint = trailingConstraint {
                    contentView.removeConstraint(trailingConstraint)
                }
                
                if leadingConstraint == nil {
                    let leading = NSLayoutConstraint(item: contentView,
                                                     attribute: .leading,
                                                     relatedBy: .equal,
                                                     toItem: transferContentView,
                                                     attribute: .leading,
                                                     multiplier: 1.0,
                                                     constant: 5.0)
                    contentView.addConstraint(leading)
                    leadingConstraint = leading
                }
                
                // Status
                if let statusTrailingConstraint = statusTrailingConstraint {
                    contentView.removeConstraint(statusTrailingConstraint)
                }
                
                if statusLeadingConstraint == nil {
                    let leading = NSLayoutConstraint(item: transferContentView,
                                                     attribute: .trailing,
                                                     relatedBy: .equal,
                                                     toItem: statusView,
                                                     attribute: .leading,
                                                     multiplier: 1.0,
                                                     constant: 12.0)
                    contentView.addConstraint(leading)
                    statusLeadingConstraint = leading
                }
            }
        }
    }
}

extension TransactionStatus {
    var image: UIImage {
        switch self {
        case .notInitiated, .updating: return #imageLiteral(resourceName: "status_updating")
        case .pending:return #imageLiteral(resourceName: "status_pending")
        case .success: return #imageLiteral(resourceName: "status_success")
        case .failed: return #imageLiteral(resourceName: "status_failed")
        }
    }
    
    var imageTintColor: UIColor {
        switch self {
        case .notInitiated, .updating: return UIColor.adamant.secondary
        case .pending, .success: return UIColor.adamant.primary
        case .failed: return UIColor.adamant.transferOutcomeIconBackground
        }
    }
}
