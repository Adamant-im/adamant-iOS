//
//  CGSize+adamant.swift
//  Adamant
//
//  Created by Andrey Golubenko on 02.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CoreGraphics

public extension CGSize {
    init(squareSize: CGFloat) {
        self.init(width: squareSize, height: squareSize)
    }
}
