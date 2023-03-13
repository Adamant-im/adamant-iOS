//
//  UIViewController+KeyboardSafeArea.swift
//  Adamant
//
//  Created by Andrey Golubenko on 14.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Combine

extension UIViewController {
    func addKeyboardToSafeArea() -> AnyCancellable {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardDidChangeFrameNotification, object: nil)
            .sink { [weak self] in self?.onKeyboardFrameChange($0) }
    }
}

private extension UIViewController {
    func onKeyboardFrameChange(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrameInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey],
            let keyboardFrame = (keyboardFrameInfo as? NSValue)?.cgRectValue
        else { return }
        
        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(
            dx: .zero,
            dy: -additionalSafeAreaInsets.bottom
        )
        
        let intersection = safeAreaFrame.intersection(keyboardFrameInView)
        
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
                self?.additionalSafeAreaInsets.bottom = intersection.height
                self?.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
}
