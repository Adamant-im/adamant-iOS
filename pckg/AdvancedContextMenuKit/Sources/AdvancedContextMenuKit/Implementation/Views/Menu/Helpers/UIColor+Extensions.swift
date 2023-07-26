//
//  UIColor+Extensions.swift
//  
//
//  Created by Stanislav Jelezoglo on 26.07.2023.
//

import UIKit

extension UIColor {
    class var destructive: UIColor {
        UIColor(red: 1, green: 0.2196078431, blue: 0.137254902, alpha: 1)
    }
    
    class func returnColorByTheme(colorWhiteTheme: UIColor, colorDarkTheme: UIColor) -> UIColor {
        UIColor { traits -> UIColor in
            return traits.userInterfaceStyle == .dark ? colorDarkTheme : colorWhiteTheme
        }
    }
}
