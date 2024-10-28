//
//  UILabel+adamant.swift
//  Adamant
//
//  Created by Andrey Golubenko on 09.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit

public extension UILabel {
    convenience init(
        font: UIFont? = nil,
        textColor: UIColor? = nil,
        numberOfLines: Int? = nil,
        alignment: NSTextAlignment? = nil
    ) {
        self.init()
        font.map { self.font = $0 }
        textColor.map { self.textColor = $0 }
        numberOfLines.map { self.numberOfLines = $0 }
        alignment.map { self.textAlignment = $0 }
    }
}
