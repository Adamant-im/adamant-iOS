//
//  CollectionCellWrapper.swift
//  Adamant
//
//  Created by Andrey Golubenko on 09.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

final class CollectionCellWrapper<View: ReusableView>: UICollectionViewCell {
    let wrappedView = View()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    override func prepareForReuse() {
        wrappedView.prepareForReuse()
    }
    
    override var isSelected: Bool {
        didSet {
            guard let view = wrappedView as? ChatTransactionContainerView else {
                wrappedView.animateIsSelected(isSelected, originalColor: wrappedView.backgroundColor)
                return
            }
            
            view.isSelected = isSelected
        }
    }
}

private extension CollectionCellWrapper {
    func configure() {
        contentView.addSubview(wrappedView)
        wrappedView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
