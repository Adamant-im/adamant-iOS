//
//  ChatScrollState.swift
//  Adamant
//
//  Created by Владимир Клевцов on 11. 4. 2025..
//  Copyright © 2025 Adamant. All rights reserved.
//
import SnapKit

struct ChatScrollState {
    var messagesLoaded = false
    var isScrollPositionNearlyTheBottom = true
    var viewAppeared = false
    var scrollToUnreadBottomConstraint: Constraint?
    var isScrollDownButtonHidden = true
    var previousUnreadCount: Int = 0
    var isAnimatingCellHighlight = false
    var isAutoScrolling = false
    var isAppActive = true
    var isScrollingToBottom = false
    
    //calculation for animate, might use for something else in the futer
    var isAllowed: Bool {
        messagesLoaded && !isAutoScrolling && !isScrollingToBottom
    }
}
