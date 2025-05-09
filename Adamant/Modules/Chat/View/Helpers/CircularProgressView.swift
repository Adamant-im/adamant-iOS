//
//  CircularProgressView.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.05.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import SwiftUI
import UIKit
import Combine

final class CircularProgressState: ObservableObject {
    let lineWidth: CGFloat
    let backgroundColor: UIColor
    let progressColor: UIColor
    @Published var progress: Double = 0
    @Published var hidden: Bool = false
    @Published var isSpinning: Bool = false
    @Published var backgroundGradient: LinearGradient? = nil
    
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
    @State private var rotationAngle: Double = 0
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 0.016, on: .main, in: .common)
    @State private var timerCancellable: Cancellable?
    
    init(state: @escaping () -> CircularProgressState) {
        _state = .init(wrappedValue: state())
    }
    
    var body: some View {
        ZStack {
            if let gradient = state.backgroundGradient {
                Circle()
                    .stroke(
                        gradient,
                        lineWidth: state.lineWidth
                    )
                    .rotationEffect(.degrees(rotationAngle))
            } else {
                Circle()
                    .stroke(
                        Color(uiColor: state.backgroundColor),
                        lineWidth: state.lineWidth
                    )
            }
            
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
        .onReceive(timer) { _ in
            if state.isSpinning {
                rotationAngle += 2
                if rotationAngle >= 360 { rotationAngle -= 360 }
            }
        }
        .onReceive(state.$isSpinning) { spinning in
            if spinning {
                timer = Timer.publish(every: 0.016, on: .main, in: .common)
                timerCancellable = timer.connect()
            } else {
                timerCancellable?.cancel()
                timerCancellable = nil
            }
        }
    }
}
