//
//  UIView+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 17.12.2024.
//

import UIKit

extension UIView {
    public func addSubviews(_ subviews: UIView...) {
        subviews.forEach { addSubview($0) }
    }
}
