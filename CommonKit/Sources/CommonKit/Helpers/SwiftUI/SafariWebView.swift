//
//  SafariWebView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 15.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import SafariServices

public struct SafariWebView: UIViewControllerRepresentable {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public func makeUIViewController(context: Context) -> SFSafariViewController {
        .init(url: url)
    }
    
    public func updateUIViewController(_: SFSafariViewController, context _: Context) {}
}
