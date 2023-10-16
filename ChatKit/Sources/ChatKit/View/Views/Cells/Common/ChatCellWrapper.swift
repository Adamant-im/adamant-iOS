//
//  ChatCellWrapper.swift
//  
//
//  Created by Andrew G on 12.10.2023.
//

import UIKit
import SnapKit

final class ChatCellWrapper<View: UIView>: UITableViewCell {
    let wrappedView = View()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
}

private extension ChatCellWrapper {
    func configure() {
        selectionStyle = .none
        contentView.transform = .init(scaleX: 1, y: -1)
        
        contentView.addSubview(wrappedView)
        wrappedView.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview().inset(12)
            $0.directionalVerticalEdges.equalToSuperview().inset(2)
        }
    }
}
