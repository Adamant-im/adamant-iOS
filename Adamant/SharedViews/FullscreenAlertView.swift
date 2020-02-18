//
//  FullscreenAlertView.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.09.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class FullscreenAlertView: UIView {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var alertBackgroundView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    // MARK: Setters & Getters
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.isHidden = newValue == nil
            titleLabel.text = newValue
        }
    }
    
    var message: String? {
        get {
            return messageLabel.text
        }
        set {
            messageLabel.isHidden = newValue == nil
            messageLabel.text = newValue
        }
    }
    
    
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        alertBackgroundView.layer.cornerRadius = 14
        titleLabel.isHidden = true
        messageLabel.isHidden = true
    }
}
