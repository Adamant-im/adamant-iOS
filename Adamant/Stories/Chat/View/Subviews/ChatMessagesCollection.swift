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
        contentSize.height + fullInsets.bottom - bounds.maxY
    }
    
    var fullInsets: UIEdgeInsets {
        safeAreaInsets + contentInset
    }
    
    // To prevent value changes by MessageKit. Insets can be set via `setFullBottomInset` only
    override var contentInset: UIEdgeInsets {
        get { super.contentInset }
        set {}
    }
    
    // To prevent value changes by MessageKit. Insets can be set via `setFullBottomInset` only
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
    
    func reloadData(newModels: [ChatMessage]) {
        guard newModels.last == currentModels.last || currentModels.isEmpty else {
            return applyNewModels(newModels)
        }
        
        if Set(newModels.map { $0.id }) != Set(currentModels.map { $0.id }) {
            stopDecelerating()
        }
        
        let bottomOffset = self.bottomOffset
        applyNewModels(newModels)
        setBottomOffset(bottomOffset, safely: !isDragging && !isDecelerating)
    }
    
    func setFullBottomInset(_ inset: CGFloat) {
        let inset = inset - safeAreaInsets.bottom
        let bottomOffset = self.bottomOffset
        super.contentInset.bottom = inset
        super.verticalScrollIndicatorInsets.bottom = inset

        guard !hasActiveScrollGestures else { return }
        setBottomOffset(bottomOffset, safely: false)
    }
    
    func setBottomOffset(_ newValue: CGFloat, safely: Bool) {
        setVerticalContentOffset(
            maxVerticalOffset - newValue,
            safely: safely
        )
    }
}

private extension ChatMessagesCollectionView {
    var maxVerticalOffset: CGFloat {
        contentSize.height + fullInsets.bottom - bounds.height
    }
    
    var minVerticalOffset: CGFloat {
        -fullInsets.top
    }
    
    var scrollGestureRecognizers: [UIGestureRecognizer] {
        [panGestureRecognizer, pinchGestureRecognizer].compactMap { $0 }
    }
    
    var hasActiveScrollGestures: Bool {
        scrollGestureRecognizers.contains {
            switch $0.state {
            case .began, .changed:
                return true
            case .ended, .cancelled, .possible, .failed:
                return false
            @unknown default:
                return false
            }
        }
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
        guard maxVerticalOffset > minVerticalOffset else { return }
        
        var offset = offset
        if safely {
            if offset > maxVerticalOffset {
                offset = maxVerticalOffset
            } else if offset < minVerticalOffset {
                offset = minVerticalOffset
            }
        }
        
        contentOffset.y = offset
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
