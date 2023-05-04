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
    private var messagePadding: CGFloat = 0
    private var replyAction: Bool = false
    private var canReplyVibrate: Bool = true
    private var oldContentOffset: CGPoint?
    
    var action: ((MessageModel) -> Void)?
    var swipeStateAction: ((SwipeableView.State) -> Void)?
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewForSwipe = self
        setup()
    }
    
    init(frame: CGRect, view: UIView, messagePadding: CGFloat = 0) {
        super.init(frame: frame)
        self.messagePadding = messagePadding
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
            action: #selector(swipeGestureCellAction(_:)),
            message: ChatMessageCell.Model.default
        )
        viewForSwipe?.addGestureRecognizer(panGestureRecognizer!)
    }
    
    func update(_ model: MessageModel) {
        panGestureRecognizer?.message = model
    }
    
    // MARK: Actions
    
    func didSwipe(_ message: MessageModel) {
        action?(message)
    }
}

// MARK: UIPanGestureRecognizer

private extension SwipeableView {
    @objc func swipeGestureCellAction(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: viewForSwipe)
        
        guard let movingView = recognizer.view?.superview as? UIView,
              let panGesture = recognizer as? SwipePanGestureRecognizer
        else {
            return
        }
        
        if recognizer.state == .began {
            swipeStateAction?(.began)
        }
        
        let isOnStartPosition = movingView.frame.origin.x == 0 || movingView.frame.origin.x == messagePadding
        
        if isOnStartPosition && translation.x > 0 { return }
        
        if movingView.frame.origin.x <= messagePadding {
            movingView.center = CGPoint(
                x: movingView.center.x + translation.x / 2,
                y: movingView.center.y
            )
            recognizer.setTranslation(CGPoint(x: 0, y: 0), in: viewForSwipe)
            
            if abs(movingView.frame.origin.x) > UIScreen.main.bounds.size.width * 0.18 {
                replyAction = true
                if canReplyVibrate {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
                canReplyVibrate = false
            } else {
                replyAction = false
            }
        }
        
        if recognizer.state == .ended {
            swipeStateAction?(.ended)
            canReplyVibrate = true
            
            if replyAction {
                didSwipe(panGesture.message)
            }
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                movingView.frame = CGRect(
                    x: self.messagePadding,
                    y: movingView.frame.origin.y,
                    width: movingView.frame.size.width,
                    height: movingView.frame.size.height
                )
            }
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
