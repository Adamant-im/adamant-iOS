//
//  NodeCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import Eureka
import CommonKit
import Combine

final class NodeCell: Cell<NodeCell.Model>, CellType {
    private let checkmarkRowView = CheckmarkRowView()
    private var subscription: AnyCancellable?
    
    private var model: Model = .default {
        didSet {
            guard model != oldValue else { return }
            baseRow.baseValue = model
            update()
        }
    }
    
    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func update() {
        checkmarkRowView.setIsChecked(model.isEnabled, animated: true)
        checkmarkRowView.title = model.title
        checkmarkRowView.captionColor = getIndicatorColor(status: model.connectionStatus)
        
        checkmarkRowView.caption = ["●", makeActivitiesString()]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let descriptionStrings = [
            model.statusString,
            model.versionString,
            model.heightString
        ]
        
        checkmarkRowView.subtitle = descriptionStrings
            .compactMap { $0 }
            .joined(separator: " ")
    }
    
    func subscribe<P: Observable<Model>>(_ publisher: P) {
        subscription = publisher
            .removeDuplicates()
            .sink { [weak self] in self?.model = $0 }
    }
}

private extension NodeCell {
    func setupView() {
        contentView.addSubview(checkmarkRowView)
        checkmarkRowView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        checkmarkRowView.checkmarkImage = .asset(named: "status_success")
        checkmarkRowView.onCheckmarkTap = { [weak self] in self?.onCheckmarkTap()}
    }
    
    func onCheckmarkTap() {
        model.nodeUpdateAction.value(!checkmarkRowView.isChecked)
    }
    
    func makeActivitiesString() -> String? {
        model.activities.map { activity in
            switch activity {
            case .webSockets:
                return "ws"
            case let .rest(scheme):
                return scheme.rawValue
            }
        }.sorted().joined(separator: ", ")
    }
}

final class NodeRow: Row<NodeCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        cellProvider = .init()
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
