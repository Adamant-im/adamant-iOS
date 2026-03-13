//
//  InteractiveBackgroundView.swift
//
//
//  Created by Dmitrij Meidus on 06.03.2026.
//

import SwiftUI
import UIKit

/// A UIViewRepresentable that wraps a real UIView with a background color.
/// Unlike SwiftUI's Color, this creates an actual UIKit subview
/// that TransparentWindow._hitTest can detect for proper hit testing.
struct InteractiveBackgroundView: UIViewRepresentable {
    let color: UIColor

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.isUserInteractionEnabled = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
