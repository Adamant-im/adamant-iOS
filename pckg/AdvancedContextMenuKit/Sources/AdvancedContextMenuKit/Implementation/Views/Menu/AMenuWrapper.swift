//
//  AMenuWrapper.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI

struct AMenuWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = AMenuViewController
    
    let view: UIViewControllerType
    
    func makeUIViewController(context: Context) -> AMenuViewController {
        return view
    }
    
    func updateUIViewController(_ uiView: AMenuViewController, context: Context) { }
}
