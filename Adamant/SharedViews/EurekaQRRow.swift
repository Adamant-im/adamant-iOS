//
//  EurekaQRRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

public class QrCell: Cell<UIImage>, CellType {
    @IBOutlet weak var qrImageView: UIImageView!
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
    
    public override func update() {
        super.update()
        qrImageView.image = row.value
    }
}

public final class QrRow: Row<QrCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        // We set the cellProvider to load the .xib corresponding to our cell
        cellProvider = CellProvider<QrCell>(nibName: "QrCell")
    }
}
