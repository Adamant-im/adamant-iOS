//
//  ChatTransactionCell.swift
//  Adamant
//
//  Created by Andrey Golubenko on 20.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class ChatTransactionCell: UICollectionViewCell {
    let transactionView = ChatTransactionContainerView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func prepareForReuse() {
        transactionView.prepareForReuse()
    }
    
    override var isSelected: Bool {
        didSet {
            transactionView.animateIsSelected(isSelected, originalColor: transactionView.backgroundColor)
            transactionView.isSelected = isSelected
        }
    }
}

private extension ChatTransactionCell {
    func configure() {
        contentView.addSubview(transactionView)
        transactionView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
