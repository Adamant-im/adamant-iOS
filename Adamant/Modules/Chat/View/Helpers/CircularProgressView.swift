//
//  CircularProgressView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.05.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import UIKit

final class CircularProgressState: ObservableObject {
    let lineWidth: CGFloat
    let backgroundColor: UIColor
    let progressColor: UIColor
    @Published var progress: Double = 0
    @Published var hidden: Bool = false
    
    init(
        lineWidth: CGFloat = 6,
        backgroundColor: UIColor = .lightGray,
        progressColor: UIColor = .blue,
        progress: Double,
        hidden: Bool
    ) {
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.progressColor = progressColor
        self.progress = progress
        self.hidden = hidden
    }
}

struct CircularProgressView: View {
    @StateObject private var state: CircularProgressState
    
    init(state: @escaping () -> CircularProgressState) {
        _state = .init(wrappedValue: state())
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(uiColor: state.backgroundColor),
                    lineWidth: state.lineWidth
                )
            Circle()
                .trim(from: 0, to: state.progress)
                .stroke(
                    Color(uiColor: state.progressColor),
                    style: StrokeStyle(
                        lineWidth: state.lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: state.progress)
        }
        .opacity(state.hidden ? .zero : 1.0)
    }
}
