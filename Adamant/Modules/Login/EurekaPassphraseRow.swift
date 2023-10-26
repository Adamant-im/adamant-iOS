//
//  EurekaPassphraseRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

public class PassphraseCell: Cell<String>, CellType {
    @IBOutlet weak var passphraseLabel: UILabel!
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var bottomConstrain: NSLayoutConstraint!
    
    var tipLabelIsHidden: Bool = false {
        didSet {
            if tipLabelIsHidden {
                bottomConstrain.constant = 0
                tipLabel.isHidden = true
            } else {
                bottomConstrain.constant = 33
                tipLabel.isHidden = false
            }
        }
    }
    
    var passphrase: String? {
        get {
            return passphraseLabel.text
        }
        set {
            passphraseLabel.text = newValue
        }
    }
    
    var tip: String? {
        get {
            return tipLabel.text
        }
        set {
            tipLabel.text = newValue
        }
    }
    
    public override func update() {
        passphraseLabel.text = row.value
    }
}

public final class PassphraseRow: Row<PassphraseCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        // We set the cellProvider to load the .xib corresponding to our cell
        cellProvider = CellProvider<PassphraseCell>(nibName: "PassphraseCell")
    }
}
