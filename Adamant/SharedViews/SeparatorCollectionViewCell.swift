//
//  SeparatorCollectionViewCell.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class SeparatorCollectionViewCell: UICollectionViewCell, ChatCell {
    var bubbleBackgroundColor: UIColor? = .clear
    
    @IBOutlet weak private var leftSeparator: UIView!
    @IBOutlet weak private var rightSeparator: UIView!
    
    @IBOutlet weak var label: UILabel!
    
    public var color: UIColor {
        set {
            label.textColor = newValue
            leftSeparator.backgroundColor = newValue
            rightSeparator.backgroundColor = newValue
        }
        
        get {
            return label.textColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
