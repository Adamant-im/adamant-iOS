//
//  SwipePanGesture.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

final class SwipePanGestureRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        delegate = self
    }
    
    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        
        let velocity = panGesture.velocity(in: self.view)
        let isHorizontal = abs(velocity.x) > abs(velocity.y)
        return isHorizontal
    }
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
