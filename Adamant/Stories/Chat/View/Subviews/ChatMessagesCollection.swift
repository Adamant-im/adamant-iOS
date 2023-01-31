//
//  ChatMessagesCollection.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import MessageKit
import UIKit

final class ChatMessagesCollectionView<
    SectionModel: Identifiable & Equatable
>: MessagesCollectionView {
    private var currentModels = [SectionModel]()
    
    var reportMessageAction: ((IndexPath) -> Void)?
    var removeMessageAction: ((IndexPath) -> Void)?
    var fixedBottomOffset: CGFloat?
    
    var bottomOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.maxY
    }
    
    var fullInsets: UIEdgeInsets {
        safeAreaInsets + contentInset
    }
    
    override var contentInset: UIEdgeInsets {
        get { super.contentInset }
        set {}
    }
    
    override var verticalScrollIndicatorInsets: UIEdgeInsets {
        get { super.verticalScrollIndicatorInsets }
        set {}
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let fixedBottomOffset = fixedBottomOffset, bottomOffset != fixedBottomOffset {
            setBottomOffset(fixedBottomOffset, safely: true)
        }
    }
    
    /// Saves the distance to the bottom while usual reloadSections(_) saves the distance to the top
    func reloadSectionsWithFixedBottom(_ sections: IndexSet) {
        let bottomOffset = self.bottomOffset
        reloadSections(sections)
        layoutIfNeeded()
        setBottomOffset(bottomOffset, safely: true)
    }
    
    func reloadData(newModels: [SectionModel]) {
        guard newModels.last == currentModels.last || currentModels.isEmpty else {
            return applyNewModels(newModels)
        }
        
        if Set(newModels.map { $0.id }) != Set(currentModels.map { $0.id }) {
            stopDecelerating()
        }
        
        let bottomOffset = self.bottomOffset
        applyNewModels(newModels)
        setBottomOffset(bottomOffset, safely: true)
    }
    
    func setFullBottomInset(_ inset: CGFloat) {
        let inset = inset - safeAreaInsets.bottom
        let bottomOffset = self.bottomOffset
        super.contentInset.bottom = inset
        super.verticalScrollIndicatorInsets.bottom = inset

        guard !isDragging || isDecelerating else { return }
        setBottomOffset(bottomOffset, safely: false)
    }
    
    func setBottomOffset(_ newValue: CGFloat, safely: Bool) {
        setVerticalContentOffset(
            contentHeightWithBottomInsets - bounds.height - newValue,
            safely: safely
        )
    }
}

private extension ChatMessagesCollectionView {
    var maxVerticalOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.height
    }
    
    var minVerticalOffset: CGFloat {
        -fullInsets.top
    }
    
    var contentHeightWithBottomInsets: CGFloat {
        contentSize.height + fullInsets.bottom
    }
    
    func applyNewModels(_ newModels: [SectionModel]) {
        reloadData()
        layoutIfNeeded()
        currentModels = newModels
    }
    
    func stopDecelerating() {
        setContentOffset(contentOffset, animated: false)
    }
    
    func setVerticalContentOffset(_ offset: CGFloat, safely: Bool) {
        guard maxVerticalOffset > .zero else { return }
        
        var offset = offset
        if safely {
            if offset < .zero {
                offset = minVerticalOffset
            } else if offset > maxVerticalOffset {
                offset = maxVerticalOffset
            }
        }
        
        contentOffset.y = offset
    }
}
