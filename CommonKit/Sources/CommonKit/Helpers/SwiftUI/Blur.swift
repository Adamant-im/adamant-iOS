//
//  Blur.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI

public struct Blur: UIViewRepresentable {
    private let style: UIBlurEffect.Style
    
    public func makeUIView(context: Context) -> UIVisualEffectView {
        .init(effect: UIBlurEffect(style: style))
    }
    
    public func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
    
    public init(style: UIBlurEffect.Style) {
        self.style = style
    }
}
