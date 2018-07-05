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
    @IBOutlet weak var latencyLabel: UILabel?
    
	public override func update() {
        if let node = row.value {
            textLabel?.text = node.asString()
            if node.latency != Int.max {
                latencyLabel?.text = "◉\(node.latency) ms"
                latencyLabel?.textColor = node.latencyColor()
            } else {
                latencyLabel?.text = ""
            }
        }
        
	}
}

final class NodeRow: Row<NodeCell>, RowType {
	required public init(tag: String?) {
		super.init(tag: tag)
		cellProvider = CellProvider<NodeCell>(nibName: "NodeRow")
	}
}

extension Node {
    func latencyColor() -> UIColor {
        switch latency {
        case 0..<50:
            return UIColor.green
        case 50..<100:
            return UIColor.orange
        default:
            return UIColor.red
        }
    }
}
