//
//  UIEdgeInsets+adamant.swift
//  Adamant
//
//  Created by Andrey Golubenko on 08.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

extension UIEdgeInsets {
    static func +(lhs: Self, rhs: Self) -> UIEdgeInsets {
        .init(
            top: lhs.top + rhs.top,
            left: lhs.left + rhs.left,
            bottom: lhs.bottom + rhs.bottom,
            right: lhs.right + rhs.right
        )
    }
}
