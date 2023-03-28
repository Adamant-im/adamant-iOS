//
//  SwipePanGesture.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

class SwipePanGestureRecognizer: UIPanGestureRecognizer, UIGestureRecognizerDelegate {

    private var initialTouchLocation: CGPoint?
    private let minHorizontalOffset: CGFloat = 5

    var message: MessageModel
    
    init(target: Any?, action: Selector?, message: MessageModel) {
        self.message = message
        super.init(target: target, action: action)
        delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.initialTouchLocation = touches.first?.location(in: self.view)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if self.state == .possible,
           abs((touches.first?.location(in: self.view).x ?? 0) - (self.initialTouchLocation?.x ?? 0)) >= self.minHorizontalOffset {
            self.state = .changed
        }
    }
    
//    func gestureRecognizer(
//        _ gestureRecognizer: UIGestureRecognizer,
//        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
//    ) -> Bool {
//        return true
//    }
}
