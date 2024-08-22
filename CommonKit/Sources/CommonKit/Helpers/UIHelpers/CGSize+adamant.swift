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

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}
