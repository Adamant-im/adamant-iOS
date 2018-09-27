//
//  TransferCollectionViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
//import MessageKit

class TransferCollectionViewCell: UICollectionViewCell, ChatCell {
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        bubbleView.layer.cornerRadius = 16.0
    }
    
//    override var frame: CGRect {
//        didSet {
//            bubbleImageView?.setNeedsDisplay()
//        }
//    }
//
//    override var bounds: CGRect {
//        didSet {
//            bubbleImageView?.setNeedsDisplay()
//        }
//    }
    
//    var bubbleStyle: MessageStyle {
//        get { return bubbleImageView.style }
//        set { bubbleImageView.style = newValue }
//    }
    
    var bubbleBackgroundColor: UIColor? {
        get { return bubbleView.backgroundColor }
        set { bubbleView.backgroundColor = newValue }
    }
    
    var isAlignedRight: Bool = false {
        didSet {
            if isAlignedRight {
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
            } else {
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
            }
        }
    }
}
