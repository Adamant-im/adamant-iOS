//
//  EurekaQRRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

// Custom Cell with value type: Bool
// The cell is defined using a .xib, so we can set outlets :)
public class QrCell: Cell<UIImage>, CellType {
	@IBOutlet weak var qrImageView: UIImageView!
	@IBOutlet weak var tapToSaveLabel: UILabel!
	
	public override func update() {
		qrImageView.image = row.value
	}
}

// The custom Row also has the cell: CustomCell and its correspond value
public final class QrRow: Row<QrCell>, RowType {
	required public init(tag: String?) {
		super.init(tag: tag)
		// We set the cellProvider to load the .xib corresponding to our cell
		cellProvider = CellProvider<QrCell>(nibName: "QrCell")
	}
}
