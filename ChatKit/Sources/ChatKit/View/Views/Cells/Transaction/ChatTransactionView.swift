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
    
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
}

extension ChatTransactionView: ReusableView {
    func prepareForReuse() {}
}

private extension ChatTransactionView {
    func configure() {
        addSubview(label)
        label.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        update()
    }
    
    func update() {
        label.text = "tx: " + model.content.title
    }
}
