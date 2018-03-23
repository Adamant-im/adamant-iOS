//
//  EurekaAccountRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 17.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

public class AccountCell: Cell<String>, CellType {
	@IBOutlet weak var avatarImageView: UIImageView!
	@IBOutlet weak var addressLabel: UILabel!
	
	public override func update() {
		super.update()
		addressLabel.text = row.value
	}
}

public final class AccountRow: Row<AccountCell>, RowType {
	required public init(tag: String?) {
		super.init(tag: tag)
		cellProvider = CellProvider<AccountCell>(nibName: "AccountCell")
	}
}
