//
//  ChatReactionsStackView.swift
//  
//
//  Created by Andrew G on 15.10.2023.
//

import UIKit
import SnapKit
import CommonKit

final class ChatReactionsStackView: UIView, Modelable {
    var modelStorage: ChatReactionsStackModel = .default {
        didSet { update() }
    }
    
    private let firstReactionView = ChatReactionView()
    private let secondReactionView = ChatReactionView()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [firstReactionView, secondReactionView])
        view.spacing = 6
        view.alignment = .center
        return view
    }()
    
    init(axis: NSLayoutConstraint.Axis) {
        super.init(frame: .zero)
        stackView.axis = axis
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ChatReactionsStackView {
    func configure() {
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        update()
    }
    
    func update() {
        model.first.map { firstReactionView.model = $0 }
        model.second.map { secondReactionView.model = $0 }
        firstReactionView.isHidden = model.first == nil
        secondReactionView.isHidden = model.second == nil
    }
}
