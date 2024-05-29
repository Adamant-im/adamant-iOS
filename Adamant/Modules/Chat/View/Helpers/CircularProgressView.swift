//
//  CircularProgressView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.05.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import UIKit

class CircularProgressState: ObservableObject {
    @Published var lineWidth: CGFloat = 6
    @Published var backgroundColor: UIColor = .lightGray
    @Published var progressColor: UIColor = .blue
    @Published var progress: Double = 0
    @Published var hidden: Bool = false
    
    init(
        lineWidth: CGFloat,
        backgroundColor: UIColor,
        progressColor: UIColor,
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
    @EnvironmentObject private var state: CircularProgressState
    
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
