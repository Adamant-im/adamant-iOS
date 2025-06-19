//
//  ChatMessagesCollection.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import MessageKit
import UIKit

final class ChatMessagesCollectionView: MessagesCollectionView {
    private var currentIds = [String]()

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

    func reloadData(newIds: [String], isOnBottom: Bool) {
        //Check for non-UUID for messages so that bot generated messages are not included in comparison
        let topNewId = firstNonUUID(from: newIds)
        let topCurrentId = firstNonUUID(from: currentIds)

        let hasNewMessagesAtTop = topNewId != topCurrentId
        let hasNewMessagesAtBottom = newIds.last != currentIds.last
        let hasSameOrMoreMessages = newIds.count >= currentIds.count

        guard hasNewMessagesAtTop || hasNewMessagesAtBottom, hasSameOrMoreMessages else {
            return applyNewIds(newIds)
        }

        let bottomOffset = self.bottomOffset
        applyNewIds(newIds)

        if hasNewMessagesAtTop || (hasNewMessagesAtBottom && isOnBottom) {
            setBottomOffset(bottomOffset, safely: !isDragging && !isDecelerating)
        }
    }

    func setFullBottomInset(_ inset: CGFloat) {
        let inset = inset - safeAreaInsets.bottom
        let bottomOffset =
            contentSize.height < bounds.height
            ? 0
            : self.bottomOffset

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

    func stopDecelerating() {
        setContentOffset(contentOffset, animated: false)
    }
    
    func enableKeyboardDismissOnTap(targetView: UIView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        self.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        self.superview?.endEditing(true)
    }
}

fileprivate extension ChatMessagesCollectionView {
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

    func applyNewIds(_ newIds: [String]) {
        reloadData()
        layoutIfNeeded()
        currentIds = newIds
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
    
    func isUUID(_ id: String) -> Bool {
        id.contains("-") && id.count >= 36
    }
    
    func firstNonUUID(from ids: [String]) -> String? {
        ids.first(where: { !isUUID($0) })
    }
}
