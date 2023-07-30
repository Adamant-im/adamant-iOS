//
//  UIViewControllerWrapper.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI

struct UIViewControllerWrapper<T: UIViewController>: UIViewControllerRepresentable {
    typealias UIViewControllerType = T
    
    let wrappedViewController: UIViewControllerType
    
    init(_ wrappedViewController: UIViewControllerType) {
        self.wrappedViewController = wrappedViewController
    }
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        return wrappedViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
}
