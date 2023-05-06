//
//  Extensions.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI

extension Axis.Set {
    static var all = Axis.Set([.vertical, .horizontal])
}

extension View {
    func asAnyView() -> AnyView {
        AnyView(self)
    }
    
    func expanded(
        _ axes: Axis.Set = .all,
        alignment: Alignment = .center
    ) -> some View {
        var resultView = self.asAnyView()
        if axes.contains(.vertical) {
            resultView = resultView
                .frame(maxHeight: .infinity, alignment: alignment)
                .asAnyView()
        }
        if axes.contains(.horizontal) {
            resultView = resultView
                .frame(maxWidth: .infinity, alignment: alignment)
                .asAnyView()
        }
        return resultView
    }
    
    func frame(squareSize: CGFloat, alignment: Alignment = .center) -> some View {
        frame(width: squareSize, height: squareSize, alignment: alignment)
    }
}

extension DragGesture.Value {
    var velocity: CGSize {
        .init(width: predictedEndLocation.x - location.x, height: predictedEndLocation.y - location.y)
    }
}
