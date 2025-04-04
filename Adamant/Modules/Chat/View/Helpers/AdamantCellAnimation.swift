//
//  UIView+adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 20.04.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import UIKit

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
    
    func animateHighlight(
        highlightColor: UIColor = UIColor.adamant.active.withAlphaComponent(0.5),
        duration: TimeInterval = 2.5
    ) {
        let originalColor = self.backgroundColor
        
        UIView.animate(withDuration: 0.35, animations: {
            self.backgroundColor = highlightColor
        }, completion: { _ in
            UIView.animate(withDuration: duration - 0.35) {
                self.backgroundColor = originalColor
            }
        })
    }
    
    func animateHighlightOverlay(
        overlayColor: UIColor = UIColor.adamant.active.withAlphaComponent(0.5)
    ) {
        let overlay = UIView(frame: bounds)
        overlay.backgroundColor = overlayColor
        overlay.alpha = 1
        overlay.isUserInteractionEnabled = false
        overlay.layer.cornerRadius = layer.cornerRadius
        overlay.layer.masksToBounds = true
        
        addSubview(overlay)
        bringSubviewToFront(overlay)
        
        UIView.animate(withDuration: 1.5, delay: 0.5, options: [.curveEaseOut], animations: {
            overlay.alpha = 0
        }, completion: { _ in
            overlay.removeFromSuperview()
        })
    }
}
