//
//  BalanceTableViewCell
//  Adamant
//
//  Created by Anokhov Pavel on 30.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import FreakingSimpleRoundImageView

// MARK: - Value struct
public struct BalanceRowValue: Equatable {
    let crypto: String
    let fiat: String?
    let alert: Int?
}

// MARK: - Cell
public final class BalanceTableViewCell: Cell<BalanceRowValue>, CellType {
    
    // MARK: Constants
    static let compactHeight: CGFloat = 50.0
    static let fullHeight: CGFloat = 58.0
    
    // MARK: IBOutlets
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var cryptoBalanceLabel: UILabel!
    @IBOutlet var fiatBalanceLabel: UILabel!
    @IBOutlet var alertLabel: RoundedLabel!
    
    // MARK: Properties
    var cryptoValue: String? {
        get {
            return cryptoBalanceLabel.text
        }
        set {
            cryptoBalanceLabel.text = newValue
        }
    }
    
    var fiatValue: String? {
        get {
            return fiatBalanceLabel.text
        }
        set {
            fiatBalanceLabel.text = newValue
            fiatBalanceLabel.isHidden = newValue == nil
        }
    }
    
    var alertValue: Int? {
        get {
            if let raw = alertLabel.text {
                return Int(raw)
            } else {
                return nil
            }
        }
        set {
            if let raw = newValue {
                alertLabel.text = String(raw)
                alertLabel.isHidden = false
            } else {
                alertLabel.isHidden = true
            }
        }
    }
    
    // MARK: Update
    public override func update() {
        super.update()
        alertLabel.clipsToBounds = true
        alertLabel.textInsets = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
        
        if let value = row.value {
            cryptoValue = value.crypto
            fiatValue = value.fiat
            alertValue = value.alert
            
            if let r = row as? BalanceRow {
                alertLabel.backgroundColor = r.alertBackgroundColor
                alertLabel.textColor = r.alertTextColor
            }
        } else {
            cryptoBalanceLabel.isHidden = true
            fiatBalanceLabel.isHidden = true
            alertLabel.isHidden = true
        }
    }
}


// MARK: - Row
public final class BalanceRow: Row<BalanceTableViewCell>, RowType {
    var alertBackgroundColor: UIColor?
    var alertTextColor: UIColor?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        // We set the cellProvider to load the .xib corresponding to our cell
        cellProvider = CellProvider<BalanceTableViewCell>(nibName: "BalanceTableViewCell")
    }
}
