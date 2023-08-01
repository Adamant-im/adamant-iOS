//
//  MessageCellWrapper.swift
//  Adamant
//
//  Created by Andrey Golubenko on 02.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit
import SnapKit
import CommonKit

final class MessageCellWrapper<View: ReusableView>: MessageReusableView {
    let wrappedView = View()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override func prepareForReuse() {
        wrappedView.prepareForReuse()
    }
}

private extension MessageCellWrapper {
    func configure() {
        addSubview(wrappedView)
        wrappedView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
    }
}
