//
//  View+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 16.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

extension Axis.Set {
    public static var all: Axis.Set { .init([.vertical, .horizontal]) }
}

extension View {
    public func frame(squareSize: CGFloat, alignment: Alignment = .center) -> some View {
        frame(width: squareSize, height: squareSize, alignment: alignment)
    }

    public func eraseToAnyView() -> AnyView {
        .init(self)
    }

    public func expanded(
        axes: Axis.Set = .all,
        alignment: Alignment = .center
    ) -> some View {
        var resultView = eraseToAnyView()
        if axes.contains(.vertical) {
            resultView =
                resultView
                .frame(maxHeight: .infinity, alignment: alignment)
                .eraseToAnyView()
        }
        if axes.contains(.horizontal) {
            resultView =
                resultView
                .frame(maxWidth: .infinity, alignment: alignment)
                .eraseToAnyView()
        }
        return resultView
    }

    public func fullScreen() -> some View {
       return frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }

    @ViewBuilder
    public func withoutListBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self.onAppear {
                UITableView.appearance().backgroundColor = .clear
            }
        }
    }
}
