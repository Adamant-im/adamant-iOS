//
//  SwipeableView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SnapKit

class SwipeableView: UIView {
    
    // MARK: Proprieties
    
    weak var viewForSwipe: UIView?
    
    private var panGestureRecognizer: SwipePanGestureRecognizer?
    private var xPadding: CGFloat = 0
    private var isSwipedEnough: Bool = false
    private var isNeedToVibrate: Bool = true
    private var oldContentOffset: CGPoint?
    
    var didSwipeAction: (() -> Void)?
    var swipeStateAction: ((SwipeableView.State) -> Void)?
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewForSwipe = self
        setup()
    }
    
    init(frame: CGRect, view: UIView, xPadding: CGFloat = 0) {
        super.init(frame: frame)
        self.xPadding = xPadding
        viewForSwipe = view
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: Setup
    
    private func setup() {
        panGestureRecognizer = SwipePanGestureRecognizer(
            target: self,
            action: #selector(swipeGestureCellAction(_:))
        )
        viewForSwipe?.addGestureRecognizer(panGestureRecognizer!)
    }
}

// MARK: UIPanGestureRecognizer

private extension SwipeableView {
    @objc func swipeGestureCellAction(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: viewForSwipe)
        
        guard let movingView = recognizer.view?.superview as? UIView else {
            return
        }
        
        if recognizer.state == .began {
            swipeStateAction?(.began)
        }
        
        let isOnStartPosition = movingView.frame.origin.x == 0 || movingView.frame.origin.x == xPadding
        
        if isOnStartPosition && translation.x > 0 {
            swipeStateAction?(.ended)
            return
        }
        
        if movingView.frame.origin.x <= xPadding {
            movingView.center = CGPoint(
                x: movingView.center.x + translation.x / 2,
                y: movingView.center.y
            )
            recognizer.setTranslation(CGPoint(x: 0, y: 0), in: viewForSwipe)
            
            if abs(movingView.frame.origin.x) > UIScreen.main.bounds.size.width * 0.18 {
                isSwipedEnough = true
                if isNeedToVibrate {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                isNeedToVibrate = false
            } else {
                isSwipedEnough = false
            }
        }
        
        if recognizer.state == .ended {
            swipeStateAction?(.ended)
            isNeedToVibrate = true
            
            if isSwipedEnough {
                didSwipeAction?()
            }
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                movingView.frame = CGRect(
                    x: self.xPadding,
                    y: movingView.frame.origin.y,
                    width: movingView.frame.size.width,
                    height: movingView.frame.size.height
                )
            }
        }
        
        if recognizer.state == .cancelled || recognizer.state == .failed {
            swipeStateAction?(.ended)
        }
    }
}

// MARK: State
extension SwipeableView {
    enum State {
        case began
        case ended
    }
}
