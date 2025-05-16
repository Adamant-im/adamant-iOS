//
//  ChatScrollState.swift
//  Adamant
//
//  Created by Владимир Клевцов on 11. 4. 2025..
//  Copyright © 2025 Adamant. All rights reserved.
//
import SnapKit
import CommonKit

struct ChatViewControllerState {
    var isMessagesLoaded = false
    var isScrollPositionNearlyTheBottom = true
    var isViewAppeared = false
    var scrollToUnreadBottomConstraint: Constraint?
    var isScrollDownButtonHidden = true
    var previousUnreadCount: Int = 0
    var isAnimatingCellHighlight = false
    var isAutoScrolling = false
    var isAppActive = true
    var isScrollingToBottom = false
    var shouldScrollToNewMessages = true
    var isInitialMessagesWereUpdated = false
    
    //calculation for animation, might use for something else in the future
    var isAnimationAllowed: Bool {
        isMessagesLoaded && !isAutoScrolling && !isScrollingToBottom
    }
    var canReadChat: Bool {
        !isAutoScrolling && isViewAppeared && (!isMacOS || isAppActive)
    }
}
