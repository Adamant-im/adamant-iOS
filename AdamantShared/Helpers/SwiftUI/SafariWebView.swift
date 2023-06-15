//
//  SafariWebView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 15.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        .init(url: url)
    }
    
    func updateUIViewController(_: SFSafariViewController, context _: Context) {}
}
