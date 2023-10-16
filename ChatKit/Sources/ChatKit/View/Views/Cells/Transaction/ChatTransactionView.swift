//
//  ChatTransactionView.swift
//
//
//  Created by Andrew G on 03.10.2023.
//

import UIKit
import CommonKit

final class ChatTransactionView: UIView, Modelable {
    var modelStorage: ChatTransactionModel = .default {
        didSet { update() }
    }
    
    private let contentView = ChatTransactionContentView()
    private let reactionsView = ChatReactionsStackView(axis: .vertical)
    
    private lazy var statusButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(onStatusButtonTap), for: .touchUpInside)
        return button
    }()
    
    private let spacingView: UIView = {
        let view = UIView()
        view.setContentCompressionResistancePriority(.dragThatCanResizeScene, for: .horizontal)
        return view
    }()
    
    private let horizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = 12
        return stack
    }()
    
    private lazy var sideVerticalStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [statusButton, reactionsView])
        stack.alignment = .center
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

private extension ChatTransactionView {
    func configure() {
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        update()
    }
    
    func update() {
        contentView.model = model.content
        updateStatus(model.transactionStatus)
        reactionsView.model = model.reactions
        reactionsView.isHidden = model.reactions.isEmpty
        updateLayout()
    }
    
    func updateStatus(_ status: ChatTransactionModel.Status) {
        statusButton.setImage(status.image, for: .normal)
        statusButton.tintColor = status.imageTintColor
    }
    
    func updateLayout() {
        var viewsList = [spacingView, sideVerticalStack, contentView]
        
        viewsList = model.content.status.isSentByPartner
            ? viewsList.reversed()
            : viewsList
        
        guard horizontalStack.arrangedSubviews != viewsList else { return }
        horizontalStack.arrangedSubviews.forEach(horizontalStack.removeArrangedSubview)
        viewsList.forEach(horizontalStack.addArrangedSubview)
    }
    
    @objc func onStatusButtonTap() {
        model.statusUpdateAction.action()
    }
}

private extension ChatTransactionModel.Status {
    var image: UIImage {
        switch self {
        case .none: return .asset(named: "status_updating") ?? .init()
        case .pending: return .asset(named: "status_pending") ?? .init()
        case .success: return .asset(named: "status_success") ?? .init()
        case .failed: return .asset(named: "status_failed") ?? .init()
        case .warning: return .asset(named: "status_warning") ?? .init()
        }
    }
    
    var imageTintColor: UIColor {
        switch self {
        case .none: return .adamant.secondary
        case .pending: return .adamant.primary
        case .success: return .adamant.active
        case .failed, .warning: return .adamant.alert
        }
    }
}
