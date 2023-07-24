//
//  File.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI

/// Blocks interaction with background
public struct BlockingView: UIViewRepresentable {
    public func makeUIView(context _: Context) -> some UIView {
        UIBlockingView()
    }
    
    public func updateUIView(_: UIViewType, context _: Context) {}
    
    public init() {}
}

private final class UIBlockingView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event) ?? UIView()
    }
}
