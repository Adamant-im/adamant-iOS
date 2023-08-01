//
//  VisibleWalletsTableViewCell.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import SnapKit
import CommonKit

// MARK: Cell's Delegate
protocol AdamantVisibleWalletsCellDelegate: AnyObject {
    func delegateCell(_ cell: VisibleWalletsTableViewCell, didChangeCheckedStateTo state: Bool)
}

// MARK: - Cell
class VisibleWalletsTableViewCell: UITableViewCell {
    private let checkmarkRowView = VisibleWalletsCheckmarkRowView()
    
    weak var delegate: AdamantVisibleWalletsCellDelegate? {
        didSet {
            checkmarkRowView.onCheckmarkTap = { [weak self] in
                guard let self = self else { return }
                let newState = !self.checkmarkRowView.isChecked
                self.checkmarkRowView.setIsChecked(newState, animated: true)
                self.delegate?.delegateCell(self, didChangeCheckedStateTo: newState)
            }
        }
    }
    
    var title: String? {
        get { checkmarkRowView.title }
        set { checkmarkRowView.title = newValue }
    }
    
    var subtitle: String? {
        get { checkmarkRowView.subtitle }
        set { checkmarkRowView.subtitle = newValue }
    }
    
    var isChecked: Bool {
        get { checkmarkRowView.isChecked }
        set { checkmarkRowView.setIsChecked(newValue, animated: false) }
    }
    
    var caption: String? {
        get { checkmarkRowView.caption }
        set { checkmarkRowView.caption = newValue }
    }
    
    var logoImage: UIImage? {
        get { checkmarkRowView.logoImage }
        set { checkmarkRowView.logoImage = newValue }
    }
    
    var balance: Decimal? {
        get { checkmarkRowView.balance }
        set { checkmarkRowView.balance = newValue }
    }
    
    var unicId: String?
    
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        checkmarkRowView.checkmarkImage = .asset(named: "status_success")
        
        contentView.addSubview(checkmarkRowView)
        checkmarkRowView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
