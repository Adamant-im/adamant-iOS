//
//  CollectionCellWrapper.swift
//  Adamant
//
//  Created by Andrey Golubenko on 09.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

public final class CollectionCellWrapper<View: ReusableView>: UICollectionViewCell {
    public let wrappedView = View()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    public override func prepareForReuse() {
        wrappedView.prepareForReuse()
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
