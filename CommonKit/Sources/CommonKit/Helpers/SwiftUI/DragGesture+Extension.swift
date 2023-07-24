//
//  File.swift
//  
//
//  Created by Andrey Golubenko on 24.07.2023.
//

import SwiftUI

public extension DragGesture.Value {
    var velocity: CGSize {
        .init(
            width: predictedEndLocation.x - location.x,
            height: predictedEndLocation.y - location.y
        )
    }
}
