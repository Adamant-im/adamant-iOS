//
//  UIImage+adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 13.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension UIImage {
    func imageResized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
