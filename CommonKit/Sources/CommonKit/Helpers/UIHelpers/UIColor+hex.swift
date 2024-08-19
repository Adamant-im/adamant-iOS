//
//  UIColor+hex.swift
//  Adamant
//
//  Created by Anton Boyarkin on 30/05/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

public extension UIColor {
    convenience init(hex hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

public extension UIColor {
    /// if alpha == 1 it will return new color, if alpha == 0 it will return old color
    func mixin(infusion:UIColor, alpha: CGFloat) -> UIColor {
        let alpha2 = min(1.0, max(0, alpha))
        let beta = 1.0 - alpha2
        
        var r1: CGFloat = 0, r2: CGFloat = 0
        var g1: CGFloat = 0, g2: CGFloat = 0
        var b1: CGFloat = 0, b2: CGFloat = 0
        var a1: CGFloat = 0, a2: CGFloat = 0
        
        if getRed(&r1, green: &g1, blue: &b1, alpha: &a1) &&
            infusion.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) {
            let red     = r1 * beta + r2 * alpha2
            let green   = g1 * beta + g2 * alpha2
            let blue    = b1 * beta + b2 * alpha2
            let alpha   = a1 * beta + a2 * alpha2
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        
        return self
    }
}
