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
    /// Saves the distance to the bottom while usual reloadData() saves the distance to the top
    func reloadDataWithFixedBottom() {
        let bottomOffset = getBottomOffset()
        reloadData()
        layoutIfNeeded()
        setBottomOffset(bottomOffset)
    }
    
    /// Saves the distance to the bottom while usual reloadSections(_) saves the distance to the top
    func reloadSectionsWithFixedBottom(_ sections: IndexSet) {
        let bottomOffset = getBottomOffset()
        reloadSections(sections)
        layoutIfNeeded()
        setBottomOffset(bottomOffset)
    }
}

private extension MessagesCollectionView {
    var maxBottomOffset: CGFloat {
        contentHeightWithInsets - bounds.height
    }
    
    var contentHeightWithInsets: CGFloat {
        contentSize.height + contentInset.bottom + safeAreaInsets.bottom
    }
    
    func getBottomOffset() -> CGFloat {
        contentHeightWithInsets - bounds.maxY
    }
    
    func setBottomOffset(_ offset: CGFloat) {
        guard maxBottomOffset > .zero else { return }
        
        var offset = offset
        if offset < .zero {
            offset = .zero
        } else if offset > maxBottomOffset {
            offset = maxBottomOffset
        }
        
        let newOffset = CGPoint(
            x: contentOffset.x,
            y: contentHeightWithInsets - bounds.height - offset
        )
        
        setContentOffset(newOffset, animated: false)
    }
}
