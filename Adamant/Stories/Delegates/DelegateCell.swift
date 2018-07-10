//
//  DelegateCell.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import M13Checkbox

extension Notification.Name {
    struct AdamantDelegate {
        static let stateChanged = Notification.Name("adamant.AdamantDelegate.stateChanged")
        
        private init() {}
    }
}

extension AdamantUserInfoKey {
    struct Delegate {
        /// New state
        static let newState = "delegateSelectState"
        
        /// Delgate address
        static let address = "delegateAddress"
        
        private init() {}
    }
}

class DelegateCell: UITableViewCell {
    
    @IBOutlet weak var checkbox: M13Checkbox!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        checkbox.addTarget(self, action: #selector(self.onSelectChanged), for: UIControlEvents.valueChanged)
    }

    @objc func onSelectChanged() {
        if let address = addressLabel.text {
            let state = checkbox.checkState == .checked
            
            NotificationCenter.default.post(name: Notification.Name.AdamantDelegate.stateChanged, object: self, userInfo: [AdamantUserInfoKey.Delegate.newState: state, AdamantUserInfoKey.Delegate.address: address])
        }
    }
    
}
