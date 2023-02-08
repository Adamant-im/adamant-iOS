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
    private var currentModels = [ChatMessage]()
    
    var reportMessageAction: ((IndexPath) -> Void)?
    var removeMessageAction: ((IndexPath) -> Void)?
    var fixedBottomOffset: CGFloat?
    
    var bottomOffset: CGFloat {
        contentHeightWithBottomInsets - bounds.maxY
    }
    
    var fullInsets: UIEdgeInsets {
        safeAreaInsets + contentInset
    }
    
    var minVerticalOffset: CGFloat {
        -fullInsets.top
    }
    
    /// To avoid insets changing by MessageKit
    override var contentInset: UIEdgeInsets {
        get { super.contentInset }
        set {}
    }
    
    /// To avoid insets changing by MessageKit
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
    
    @MainActor
    func reloadData(newModels: [ChatMessage]) {
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
    
    var contentHeightWithBottomInsets: CGFloat {
        contentSize.height + fullInsets.bottom
    }
    
    func applyNewModels(_ newModels: [ChatMessage]) {
        let fullUpdate = zip(newModels, currentModels).contains {
            switch ($0.0.content, $0.1.content) {
            case (.transaction, .transaction):
                return false
            default:
                return $0.0 != $0.1
            }
        } || newModels.count != currentModels.count
        
        if fullUpdate {
            reloadData()
            layoutIfNeeded()
        } else {
            reloadTransactionCellsOnly(newModels)
        }

        currentModels = newModels
    }
    
    func stopDecelerating() {
        setContentOffset(contentOffset, animated: false)
    }
    
    func setVerticalContentOffset(_ offset: CGFloat, safely: Bool) {
        guard maxVerticalOffset > .zero else { return }
        
        contentOffset.y = safely && offset > maxVerticalOffset
            ? maxVerticalOffset
            : offset
    }
    
    func reloadTransactionCellsOnly(_ newModels: [ChatMessage]) {
        zip(visibleCells, indexPathsForVisibleItems).forEach { cell, indexPath in
            guard
                let cell = cell as? ChatViewController.TransactionCell,
                case let .transaction(model) = newModels[indexPath.section].content
            else { return }
            
            cell.wrappedView.model = model
        }
    }
}
