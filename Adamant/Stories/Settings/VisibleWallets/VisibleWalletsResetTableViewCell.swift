//
//  VisibleWalletsResetTableViewCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import CommonKit

class VisibleWalletsResetTableViewCell: UITableViewCell {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.text = .adamant.visibleWallets.reset
        return label
    }()
    
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.centerX.equalToSuperview()
        }
    }
}
