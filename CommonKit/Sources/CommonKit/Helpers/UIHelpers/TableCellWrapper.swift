//
//  TableCellWrapper.swift
//  Adamant
//
//  Created by Andrey Golubenko on 02.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

public final class TableCellWrapper<View: ReusableView>: UITableViewCell {
    public let wrappedView = View()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    public override func prepareForReuse() {
        wrappedView.prepareForReuse()
    }
}

private extension TableCellWrapper {
    func configure() {
        contentView.addSubview(wrappedView)
        wrappedView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
