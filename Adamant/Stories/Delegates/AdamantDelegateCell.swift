//
//  AdamantDelegateCell.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SnapKit

// MARK: Cell's Delegate
protocol AdamantDelegateCellDelegate: AnyObject {
    func delegateCell(_ cell: AdamantDelegateCell, didChangeCheckedStateTo state: Bool)
}

// MARK: -
class AdamantDelegateCell: UITableViewCell {
    private let checkmarkRowView = CheckmarkRowView()
    
    weak var delegate: AdamantDelegateCellDelegate? {
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
    
    var delegateIsActive: Bool = false {
        didSet {
            checkmarkRowView.caption = delegateIsActive ? "●" : "○"
        }
    }
    
    var isChecking: Bool {
        get { checkmarkRowView.isChecking }
        set { checkmarkRowView.setIsChecking(newValue, animated: false) }
    }
    
    var isUpvoted: Bool = false {
        didSet {
            checkmarkRowView.checkmarkImage = isUpvoted ? #imageLiteral(resourceName: "Downvote") : #imageLiteral(resourceName: "Upvote")
            checkmarkRowView.checkmarkImageBorderColor = isUpvoted ? UIColor.adamant.good.cgColor : UIColor.adamant.secondary.cgColor
            checkmarkRowView.checkmarkImageTintColor = isUpvoted ? .adamant.danger : .adamant.good
        }
    }
    
    required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    func setupView() {
        accessoryType = .disclosureIndicator
        checkmarkRowView.captionColor = .lightGray
        
        contentView.addSubview(checkmarkRowView)
        checkmarkRowView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
