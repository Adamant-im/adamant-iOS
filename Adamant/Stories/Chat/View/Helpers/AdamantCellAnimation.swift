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
}
