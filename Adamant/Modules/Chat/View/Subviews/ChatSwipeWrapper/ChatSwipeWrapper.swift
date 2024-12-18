//
//  ChatSwipeWrapper.swift
//  Adamant
//
//  Created by Andrew G on 16.12.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class ChatSwipeWrapper<View: UIView>: UIView {
    var model: ChatSwipeWrapperModel = .default {
        didSet { update(old: oldValue) }
    }
    
    let wrappedView: View
    
    init(_ wrappedView: View) {
        self.wrappedView = wrappedView
        super.init(frame: .zero)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ChatSwipeWrapper {
    func configure() {
        addSubview(wrappedView)
        wrappedView.snp.makeConstraints {
            $0.directionalVerticalEdges.width.leading.equalToSuperview()
        }
    }
    
    func update(old: ChatSwipeWrapperModel) {
        guard old.state != model.state else { return }
        
        wrappedView.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(model.state.value)
        }
        
        guard old.id == model.id else { return }
        
        switch model.state {
        case .idle:
            UIView.animate(
                withDuration: 0.25,
                delay: .zero,
                options: .curveEaseOut
            ) { [weak self] in self?.layoutIfNeeded() }
        case .offset:
            break
        }        
    }
}
