//
//  EurekaNodeRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class NodeCell: Cell<Node>, CellType {
	public override func update() {
        if let node = row.value {
            textLabel?.text = node.asString()
            if node.latency != Int.max { textLabel?.text = "\(textLabel?.text ?? "") \(node.latency) ms" }
        }
        
	}
}

final class NodeRow: Row<NodeCell>, RowType {
	required public init(tag: String?) {
		super.init(tag: tag)
		cellProvider = CellProvider<NodeCell>(nibName: "NodeRow")
	}
}
