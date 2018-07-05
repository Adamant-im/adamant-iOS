//
//  EurekaNodeRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

// MARK: - Localization
extension String.adamantLocalized {
    struct units {
        static let latency = NSLocalizedString("Shared.Unit.ms", comment: "Shared Ping latency unit")
        
        private init() {}
    }
}

class NodeCell: Cell<Node>, CellType {
    @IBOutlet weak var hostLabel: UILabel?
    @IBOutlet weak var latencyLabel: UILabel?
    
	public override func update() {
        if let node = row.value {
            hostLabel?.text = node.asString()
            if node.latency != Int.max {
                latencyLabel?.text = "◉ \(node.latency) \(String.adamantLocalized.units.latency)"
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
