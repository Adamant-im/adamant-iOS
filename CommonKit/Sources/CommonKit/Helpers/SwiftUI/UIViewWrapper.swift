//
//  UIViewWrapper.swift
//  
//
//  Created by Stanislav Jelezoglo on 01.08.2023.
//

import SwiftUI
import UIKit

public struct UIViewWrapper: UIViewRepresentable {
    public let view: UIView
    
    public func makeUIView(context: Context) -> UIView {
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) { }
    
    public init(view: UIView) {
        self.view = view
    }
}
