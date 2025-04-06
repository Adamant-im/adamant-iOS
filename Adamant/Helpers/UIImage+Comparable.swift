//
//  UIImage+Comparable.swift
//  CommonKit
//
//  Created by Dmitrij Meidus on 06.04.25.
//

import UIKit

extension UIImage: @retroactive Comparable {
    public static func < (lhs: UIImage, rhs: UIImage) -> Bool {
        fatalError()
    }
    
    public static func == (lhs: UIImage, rhs: UIImage) -> Bool {
        return lhs.pngData() == rhs.pngData()
    }
}
