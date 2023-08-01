//
//  EurekaNodeRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import Eureka
import CommonKit

class NodeCell: Cell<NodeCell.Model>, CellType {
    struct Model: Equatable {
        enum NodeActivity {
            case webSockets
            case rest
        }
        
        let node: Node
        let nodeUpdate: () -> Void
        let nodeActivity: (Node) -> Set<NodeActivity>
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.node == rhs.node
        }
    }
    
    private let checkmarkRowView = UICheckmarkRowView()
    private var model: NodeCell.Model? { row.value }
    
    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    public override func update() {
        checkmarkRowView.checkmarkImage = .asset(named: "status_success")
        checkmarkRowView.setIsChecked(model?.node.isEnabled ?? false, animated: true)
        checkmarkRowView.onCheckmarkTap = { [weak self] in
            guard let newValue = (self?.checkmarkRowView.isChecked).map({ !$0 }) else {
                return
            }
            
            self?.model?.node.isEnabled = newValue
            self?.model?.nodeUpdate()
        }
        
        checkmarkRowView.title = model?.node.asString()
        checkmarkRowView.captionColor = getIndicatorColor(status: model?.node.connectionStatus)
        checkmarkRowView.caption = ["●", makeActivitiesString()]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let descriptionStrings = [
            model?.node.statusString,
            model?.node.status?.version.map { "(\(NodeCell.Strings.version): \($0))" }
        ]
        
        checkmarkRowView.subtitle = descriptionStrings.compactMap { $0 }.joined(separator: " ")
    }
    
    private func makeActivitiesString() -> String? {
        guard let model = model else { return nil }
        let activities = model.nodeActivity(model.node)
        
        guard !activities.isEmpty else { return nil }
        
        return activities.map { activity in
            switch activity {
            case .webSockets:
                return "ws"
            case .rest:
                return model.node.scheme.rawValue
            }
        }.sorted().joined(separator: ", ")
    }
    
    private func setupView() {
        contentView.addSubview(checkmarkRowView)
        checkmarkRowView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}

final class NodeRow: Row<NodeCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        cellProvider = .init()
    }
}

private extension Node {
    var statusString: String? {
        switch connectionStatus {
        case .allowed:
            let ping = status.map { Int($0.ping * 1000) }
            return ping.map { "\(NodeCell.Strings.ping): \($0) \(NodeCell.Strings.milliseconds)" }
        case .synchronizing:
            return NodeCell.Strings.synchronizing
        case .offline:
            return NodeCell.Strings.offline
        case .none:
            return nil
        }
    }
}

private extension NodeCell {
    enum Strings {
        static let ping = String.localized(
            "NodesList.NodeCell.Ping",
            comment: "NodesList.NodeCell: Node ping"
        )
        
        static let milliseconds = String.localized(
            "NodesList.NodeCell.Milliseconds",
            comment: "NodesList.NodeCell: Milliseconds"
        )
        
        static let synchronizing = String.localized(
            "NodesList.NodeCell.Synchronizing",
            comment: "NodesList.NodeCell: Node is synchronizing"
        )
        
        static let offline = String.localized(
            "NodesList.NodeCell.Offline",
            comment: "NodesList.NodeCell: Node is offline"
        )
        
        static let version = String.localized(
            "NodesList.NodeCell.Version",
            comment: "NodesList.NodeCell: Node version"
        )
    }
}

private func getIndicatorColor(status: Node.ConnectionStatus?) -> UIColor {
    switch status {
    case .allowed:
        return .adamant.good
    case .synchronizing:
        return .adamant.alert
    case .offline:
        return .adamant.danger
    case .none:
        return .adamant.inactive
    }
}
