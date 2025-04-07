import AdamantWalletsKit
//
//  UIImage+adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//
import UIKit

extension UIImage {
    public static func asset(named: String) -> UIImage? {
        if let image = UIImage(named: named, in: .module, with: nil) {
            return image
        }
        if let image = WalletsImageProvider.image(named: named) {
            return image
        }

        return nil
    }

    public func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

public func getLocalImageUrl(by name: String, withExtension ext: String) -> URL? {
    Bundle.module.url(forResource: name, withExtension: ext)
}
