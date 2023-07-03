//
//  UIViewWrapper.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI
import UIKit

struct UIViewWrapper: UIViewRepresentable {
    let view: UIView
    
    func makeUIView(context: Context) -> UIView {
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}
