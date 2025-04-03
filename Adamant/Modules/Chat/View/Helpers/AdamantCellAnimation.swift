//
//  UIView+adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import CommonKit

extension UIView {
    func animateIsSelected(_ value: Bool, originalColor: UIColor?) {
        guard value else { return }
        backgroundColor = .adamant.active.withAlphaComponent(0.2)
        
        UIView.animate(withDuration: 1.0) {
            self.backgroundColor = originalColor
        }
    }
    
    func addShadow(
        shadowColor: UIColor = UIColor.black,
        shadowOffset: CGSize = .zero,
        shadowOpacity: Float = 0.55,
        shadowRadius: CGFloat = 3.0,
        masksToBounds: Bool = false,
        cornerRadius: CGFloat = 4.0
    ) {
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = shadowOffset
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.masksToBounds = masksToBounds
        layer.cornerRadius = cornerRadius
    }
    
    func animatePressDown(duration: TimeInterval = 0.1) {
        UIView.animate(withDuration: duration) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.alpha = 0.5
        }
    }
    
    func animatePressUp(duration: TimeInterval = 0.1) {
        UIView.animate(withDuration: duration) {
            self.transform = .identity
            self.alpha = 1.0
        }
    }
}
