//
//  KeyboardObservingViewController.swift
//  Adamant
//
//  Created by Andrey Golubenko on 10.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Combine

class KeyboardObservingViewController: UIViewController {
    private var subscription: AnyCancellable?
    private var keyboardFrame: CGRect = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subscription = makeKeyboardSubscription()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        additionalSafeAreaInsets.bottom = getAdditionalBottomInset(keyboardFrame: keyboardFrame)
    }
}

private extension KeyboardObservingViewController {
    func getAdditionalBottomInset(keyboardFrame: CGRect) -> CGFloat {
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(
            dx: .zero,
            dy: -additionalSafeAreaInsets.bottom
        )
        
        return safeAreaFrame.intersection(keyboardFrameInView).height
    }
    
    func makeKeyboardSubscription() -> AnyCancellable {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            .sink { [weak self] in self?.onKeyboardFrameChange($0) }
    }
    
    func onKeyboardFrameChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrameInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey],
            let keyboardFrame = (keyboardFrameInfo as? NSValue)?.cgRectValue
        else { return }
        
        self.keyboardFrame = keyboardFrame
        
        let animationDuration: TimeInterval = (
            notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? NSNumber
        )?.doubleValue ?? .zero
        
        let animationCurveRawNSN = notification
            .userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        
        let animationCurveRaw = animationCurveRawNSN?.uintValue ??
            UIView.AnimationOptions.curveEaseInOut.rawValue
        
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)
        
        UIView.animate(
            withDuration: animationDuration,
            delay: .zero,
            options: animationCurve,
            animations: { [weak self] in
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
}
