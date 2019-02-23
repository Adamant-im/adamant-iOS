//
//  ThemeTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 31/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class ThemeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var primaryColor: UIColor? {
        get {
            return colorView.backgroundColor
        }
        set {
            colorView.backgroundColor = newValue
        }
    }
    
    var secondaryColor: UIColor? {
        get {
            guard let cgColor = colorView.layer.borderColor else {
                return nil
            }
            
            return UIColor(cgColor: cgColor)
        }
        set {
            colorView.layer.borderColor = newValue?.cgColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorView.layer.cornerRadius = colorView.bounds.height/2
        colorView.layer.borderWidth = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
