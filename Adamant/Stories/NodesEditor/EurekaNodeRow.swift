//
//  EurekaNodeRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka

class NodeCell: Cell<NodeCell.Model>, CellType {
    struct Model: Equatable {
        let node: Node
        let setIsEnabled: (Bool) -> Void
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.node == rhs.node
        }
    }
    
    @IBOutlet weak var indicatorView: UILabel!
    @IBOutlet weak var checkmarkView: CheckmarkView!
    @IBOutlet weak var descriptionView: UILabel!
    @IBOutlet weak var titleView: UILabel!
    
    public override func update() {
        indicatorView.tintColor = .green
        checkmarkView.image = #imageLiteral(resourceName: "status_success")
        checkmarkView.imageColor = .adamant.primary
        checkmarkView.borderColor = .adamant.secondary
        
        let model = row.value
        
        checkmarkView.setIsChecked(model?.node.isEnabled ?? false, animated: true)
        checkmarkView.onCheckmarkTap = { [weak checkmarkView] in
            guard let newValue = (checkmarkView?.isChecked).map({ !$0 })
            else { return }
            
            model?.setIsEnabled(newValue)
        }
        
        titleView.text = model?.node.asString()
        indicatorView.textColor = getIndicatorColor(status: model?.node.connectionStatus)
        
        let descriptionStrings = [
            model?.node.statusString,
            model?.node.status?.version.map { "(version: \($0))" }
        ]
        
        descriptionView.text = descriptionStrings.compactMap { $0 }.joined(separator: " ")
    }
}

final class NodeRow: Row<NodeCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        cellProvider = CellProvider<NodeCell>(nibName: "NodeCell")
    }
}

private func getIndicatorColor(status: Node.ConnectionStatus?) -> UIColor {
    switch status {
    case .allowed:
        return .green
    case .synchronizing:
        return .yellow
    case .offline:
        return .red
    case .none:
        return .lightGray
    }
}

private extension Node {
    var statusString: String? {
        switch connectionStatus {
        case .allowed:
            let ms = (status?.ping).map { Int($0 * 1000) }
            return ms.map { "Ping: \($0) ms" } ?? "Online"
        case .synchronizing:
            return "Synchronizing"
        case .offline:
            return "Offline"
        case .none:
            return nil
        }
    }
}
