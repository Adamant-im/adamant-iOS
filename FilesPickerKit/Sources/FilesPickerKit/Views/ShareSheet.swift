//
//  ShareSheet.swift
//
//
//  Created by Stanislav Jelezoglo on 12.03.2024.
//

import Foundation
import SwiftUI

struct ShareSheet: View {
    let activityItems: [Any]
    let completion: UIActivityViewController.CompletionWithItemsHandler?
    
    var body: some View {
        ActivityView(activityItems: activityItems, completion: completion)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let completion: UIActivityViewController.CompletionWithItemsHandler?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
