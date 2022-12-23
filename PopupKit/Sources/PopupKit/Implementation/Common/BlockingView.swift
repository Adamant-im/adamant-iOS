//
//  File.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI

/// Blocks interaction with background
struct BlockingView: UIViewRepresentable {
    func makeUIView(context _: Context) -> some UIView {
        UIBlockingView()
    }
    
    func updateUIView(_: UIViewType, context _: Context) {}
}

private final class UIBlockingView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event) ?? UIView()
    }
}
