//
//  InteractiveBackgroundView.swift
//  CommonKit
//
//  Created by Dmitrij Meidus on 06.03.2026.
//

import SwiftUI
import UIKit

/// A UIViewRepresentable that wraps a real UIView with a background color.
/// Unlike SwiftUI's Color, this creates an actual UIKit subview
/// that TransparentWindow._hitTest can detect for proper hit testing.
public struct InteractiveBackgroundView: UIViewRepresentable {
    public let color: UIColor

    public init(color: UIColor) {
        self.color = color
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.isUserInteractionEnabled = true
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}
}
