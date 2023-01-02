//
//  MessageKit+Extension.swift
//  Adamant
//
//  Created by Andrey on 25.08.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import UIKit
import MessageKit

extension MessagesCollectionView {
    enum DataReloadAlignment {
        case top
        case bottom
    }
    
    func reloadData(alignment: DataReloadAlignment) {
        switch alignment {
        case .top:
            reloadData()
        case .bottom:
            reloadDataWithFixedBottom()
        }
    }
}

private extension MessagesCollectionView {
    var contentHeightWithInsets: CGFloat {
        contentSize.height + contentInset.bottom + safeAreaInsets.bottom
    }
    
    func reloadDataWithFixedBottom() {
        let bottomOffset = getBottomOffset()

        reloadData()
        layoutIfNeeded()
        
        setBottomOffset(bottomOffset)
    }
    
    func getBottomOffset() -> CGFloat {
        guard contentHeightWithInsets > bounds.height else { return .zero }
        return contentHeightWithInsets - bounds.maxY
    }
    
    func setBottomOffset(_ offset: CGFloat) {
        guard contentHeightWithInsets > bounds.height else { return }
        
        let newOffset = CGPoint(
            x: contentOffset.x,
            y: contentHeightWithInsets - bounds.height - offset
        )
        
        setContentOffset(newOffset, animated: false)
    }
}
