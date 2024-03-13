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
    
    var body: some View {
        ActivityView(activityItems: activityItems)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
