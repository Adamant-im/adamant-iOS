//
//  ChatSwipeManager.swift
//  Adamant
//
//  Created by Andrew G on 17.12.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit

@MainActor
final class ChatSwipeManager: NSObject {
    private let viewModel: ChatViewModel
    private var chatView: UIView?
    private var vibrated = false
    
    private var requiredSwipeOffset: CGFloat {
        -UIScreen.main.bounds.size.width * 0.05
    }
    
    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    func configure(chatView: UIView) {
        let recognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(onSwipe(_:))
        )
        
        recognizer.delegate = self
        chatView.addGestureRecognizer(recognizer)
        self.chatView = chatView
    }
}

extension ChatSwipeManager: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(
        _ recognizer: UIGestureRecognizer
    ) -> Bool {
        guard let recognizer = recognizer as? UIPanGestureRecognizer else {
            return false
        }
        
        let velocity = recognizer.velocity(in: chatView)
        guard abs(velocity.x) > abs(velocity.y) else { return false }
        
        let location = recognizer.location(in: chatView)
        guard let id = findChatSwipeWrapperId(location) else { return false }
        
        viewModel.updateSwipeableId(id)
        return true
    }
    
    func gestureRecognizer(
        _: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
    ) -> Bool { true }
}

private extension ChatSwipeManager {
    func findChatSwipeWrapperId(_ location: CGPoint) -> String? {
        var view = chatView?.hitTest(location, with: nil)
        
        while view != nil {
            if let swipeWrapper = view as? ChatSwipeWrapper {
                return swipeWrapper.model.id
            } else {
                view = view?.superview
            }
        }
        
        return nil
    }
    
    @objc func onSwipe(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: chatView)
        let offset = translation.x <= .zero
            ? translation.x
            : .zero
        
        switch recognizer.state {
        case .possible:
            break
        case .began:
            vibrated = false
            viewModel.enableScroll.send(false)
        case .changed:
            viewModel.updateSwipingOffset(offset)
            
            if offset > requiredSwipeOffset {
                vibrated = false
            }
            
            guard !vibrated else { break }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            vibrated = true
        case .ended, .cancelled, .failed:
            if offset <= requiredSwipeOffset {
                viewModel.replyMessageIfNeeded(id: viewModel.swipeableMessage.id)
            }
            
            viewModel.updateSwipeableId(nil)
            viewModel.enableScroll.send(true)
        @unknown default:
            break
        }
    }
}
