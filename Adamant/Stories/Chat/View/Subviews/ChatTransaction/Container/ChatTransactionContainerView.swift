//
//  ChatTransactionContainerView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 11.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import Combine

final class ChatTransactionContainerView: UIView {
    var model: Model = .default {
        didSet {
            guard model != oldValue else { return }
            update(old: oldValue)
        }
    }
    
    private let contentView = ChatTransactionContentView()
    private var statusSubscription: AnyCancellable?
    
    private let statusView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension ChatTransactionContainerView: ReusableView {
    func prepareForReuse() {
        model = .default
    }
}

private extension ChatTransactionContainerView {
    func configure() {
        addSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }
    }
    
    func update(old: Model) {
        contentView.model = model.content
        updateStatusSubscription(old: old.status)
        updateLayout()
    }
    
    func updateStatusSubscription(old: Model.Status?) {
        guard old != model.status else { return }
        guard let status = model.status else { return updateStatus(.notInitiated) }
        
        updateStatus(status.status)
        statusSubscription = status.$status
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] in self?.updateStatus($0) }
    }
    
    func updateStatus(_ status: TransactionStatus) {
        statusView.image = status.image
        statusView.tintColor = status.imageTintColor
    }
    
    func updateLayout() {
        var viewsList = [spacingView, statusView, contentView]
        
        viewsList = model.isFromCurrentSender
            ? viewsList
            : viewsList.reversed()
        
        guard horizontalStack.arrangedSubviews != viewsList else { return }
        horizontalStack.arrangedSubviews.forEach(horizontalStack.removeArrangedSubview)
        viewsList.forEach(horizontalStack.addArrangedSubview)
    }
}

private extension TransactionStatus {
    var image: UIImage {
        switch self {
        case .notInitiated, .updating: return #imageLiteral(resourceName: "status_updating")
        case .pending: return #imageLiteral(resourceName: "status_pending")
        case .success: return #imageLiteral(resourceName: "status_success")
        case .failed: return #imageLiteral(resourceName: "status_failed")
        case .warning, .dublicate: return #imageLiteral(resourceName: "status_warning")
        }
    }
    
    var imageTintColor: UIColor {
        switch self {
        case .notInitiated, .updating: return .adamant.secondary
        case .pending: return .adamant.primary
        case .success: return .adamant.active
        case .warning, .dublicate, .failed: return .adamant.alert
        }
    }
}
