//
//  ChatKeyboardManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 17.05.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

final class ChatKeyboardManager: NSObject, UIGestureRecognizerDelegate {
    private let scrollView: UIScrollView
    var panGesture: UIPanGestureRecognizer?
    
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init()
    }
    
    /// Only receive a `UITouch` event when the `scrollView`'s keyboard dismiss mode is interactive
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return scrollView.keyboardDismissMode == .interactive
    }
    
    /// Only recognice gestures when is vertical velocity
    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        
        let velocity = panGesture.velocity(in: scrollView)
        return abs(velocity.x) < abs(velocity.y)
    }
    
    /// Only recognice simultaneous gestures when its the `panGesture`
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === panGesture
    }
}
