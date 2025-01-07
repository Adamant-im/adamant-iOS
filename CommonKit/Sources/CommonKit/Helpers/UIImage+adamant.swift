//
//  UIImage+adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import AdamantWalletsAssets

public extension UIImage {
    static func asset(named: String) -> UIImage? {
        if let image = UIImage(named: named, in: .module, compatibleWith: nil) {
            return image
        }
        if let image = UIImage(named: named, in: Bundle.adamantWalletsAssets, compatibleWith: nil) {
            return image
        }
        return nil
    }
    
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
