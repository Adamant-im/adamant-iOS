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
    private var prevoiusVerticalInsets: CGFloat = .zero
    var animationEnabled = false
    
    /// Saves the distance to the bottom while usual reloadData() saves the distance to the top
    func reloadDataWithFixedBottom() {
        let bottomOffset = self.bottomOffset
        reloadData()
        layoutIfNeeded()
        self.bottomOffset = bottomOffset
    }

    /// Saves the distance to the bottom while usual reloadSections(_) saves the distance to the top
    func reloadSectionsWithFixedBottom(_ sections: IndexSet) {
        let bottomOffset = self.bottomOffset
        reloadSections(sections)
        layoutIfNeeded()
        self.bottomOffset = bottomOffset
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        moveContentIfInsetsChanged()
    }
}

private extension ChatMessagesCollectionView {
    var verticalInsets: CGFloat {
        safeAreaInsets.top
            + safeAreaInsets.bottom
            + contentInset.top
            + contentInset.bottom
    }
    
    var maxVerticalOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.height
    }
    
    var bottomOffset: CGFloat {
        get {
            contentHeightWithBottomInsets - bounds.maxY
        }
        set {
            setVerticalContentOffsetSafely(
                contentHeightWithBottomInsets - bounds.height - newValue,
                animated: false
            )
        }
    }
    
    var contentHeightWithBottomInsets: CGFloat {
        contentSize.height + contentInset.bottom + safeAreaInsets.bottom
    }
    
    func setVerticalContentOffsetSafely(_ offset: CGFloat, animated: Bool) {
        guard maxVerticalOffset > .zero else { return }
        
        var offset = offset
        if offset < .zero {
            offset = .zero
        } else if offset > maxVerticalOffset {
            offset = maxVerticalOffset
        }
        
        setContentOffset(
            .init(x: contentOffset.x, y: offset),
            animated: animated && animationEnabled
        )
    }
    
    func moveContentIfInsetsChanged() {
        guard prevoiusVerticalInsets != verticalInsets else { return }
        defer { prevoiusVerticalInsets = verticalInsets }
        
        let diff = verticalInsets - prevoiusVerticalInsets
        guard diff > .zero else { return }
        
        setVerticalContentOffsetSafely(contentOffset.y + diff, animated: true)
    }
}
