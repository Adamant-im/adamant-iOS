//
//  DoubleDetailsTableViewCell
//  Adamant
//
//  Created by Anokhov Pavel on 30.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

public struct DoubleDetail: Equatable {
    let first: String
    let second: String?
}

public final class DoubleDetailsTableViewCell: Cell<DoubleDetail>, CellType {
    
    // MARK: Constants
    static let compactHeight: CGFloat = 50.0
    static let fullHeight: CGFloat = 65.0
    
    // MARK: IBOutlets
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var detailsLabel: UILabel!
    @IBOutlet var secondDetailsLabel: UILabel!
    
    // MARK: Properties
    var secondValue: String? {
        get {
            return secondDetailsLabel.text
        }
        set {
            secondDetailsLabel.text = newValue
            if newValue == nil {
                secondDetailsLabel.isHidden = true
            }
        }
    }
    
    public override func update() {
        super.update()
        
        if let value = row.value {
            detailsLabel.text = value.first
            secondDetailsLabel.text = value.second
            
            stackView.spacing = value.second == nil ? 0 : 1
        } else {
            detailsLabel.text = nil
            secondDetailsLabel.text = nil
        }
    }
}

public final class DoubleDetailsRow: Row<DoubleDetailsTableViewCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        // We set the cellProvider to load the .xib corresponding to our cell
        cellProvider = CellProvider<DoubleDetailsTableViewCell>(nibName: "DoubleDetailsTableViewCell")
    }
}
