//
//  ChatMessagesCollection.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit

final class ChatMessagesCollectionView: MessagesCollectionView {
    var bottomOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.maxY
    }
    
    override var contentInset: UIEdgeInsets {
        get { super.contentInset }
        set {}
    }
    
    override var verticalScrollIndicatorInsets: UIEdgeInsets {
        get { super.verticalScrollIndicatorInsets }
        set {}
    }
    
    /// Saves the distance to the bottom while usual reloadData() saves the distance to the top
    func reloadDataWithFixedBottom() {
        let bottomOffset = self.bottomOffset
        reloadData()
        layoutIfNeeded()
        setBottomOffset(bottomOffset, safely: true)
    }

    /// Saves the distance to the bottom while usual reloadSections(_) saves the distance to the top
    func reloadSectionsWithFixedBottom(_ sections: IndexSet) {
        let bottomOffset = self.bottomOffset
        reloadSections(sections)
        layoutIfNeeded()
        setBottomOffset(bottomOffset, safely: true)
    }
    
    func setVerticalContentOffset(_ offset: CGFloat, safely: Bool = true) {
        guard maxVerticalOffset > .zero else { return }
        
        var offset = offset
        if safely {
            if offset < .zero {
                offset = .zero
            } else if offset > maxVerticalOffset {
                offset = maxVerticalOffset
            }
        }
        
        setContentOffset(.init(x: contentOffset.x, y: offset), animated: false)
    }
    
    func setFullBottomInset(_ inset: CGFloat) {
        let inset = inset - safeAreaInsets.bottom
        let bottomOffset = self.bottomOffset
        super.contentInset.bottom = inset
        super.verticalScrollIndicatorInsets.bottom = inset

        guard !isDragging || isDecelerating else { return }
        setBottomOffset(bottomOffset, safely: false)
    }
}

private extension ChatMessagesCollectionView {
    var fullInsets: UIEdgeInsets {
        safeAreaInsets + contentInset
    }
    
    var maxVerticalOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.height
    }
    
    var contentHeightWithBottomInsets: CGFloat {
        contentSize.height + fullInsets.bottom
    }
    
    func setBottomOffset(_ newValue: CGFloat, safely: Bool) {
        setVerticalContentOffset(
            contentHeightWithBottomInsets - bounds.height - newValue,
            safely: safely
        )
    }
}
