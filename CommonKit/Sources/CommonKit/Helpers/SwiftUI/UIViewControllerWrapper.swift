//
//  UIViewControllerWrapper.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI

public struct UIViewControllerWrapper<T: UIViewController>: UIViewControllerRepresentable {
    private let wrappedViewController: T
    
    public init(_ wrappedViewController: T) {
        self.wrappedViewController = wrappedViewController
    }
    
    public func makeUIViewController(context: Context) -> T {
        return wrappedViewController
    }
    
    public func updateUIViewController(_ uiViewController: T, context: Context) { }
}
