//
//  DocumentInteractionService.swift
//
//
//  Created by Stanislav Jelezoglo on 14.03.2024.
//

import Foundation
import UIKit
import CommonKit
import SwiftUI
import WebKit
import QuickLook

public final class DocumentInteractionService: NSObject {
    private var url: URL!
    
    public func openFile(url: URL, name: String, size: Int64, ext: String) {
        let fullName = name.contains(ext)
        ? name
        : "\(name).\(ext)"
        
        var copyURL = URL(fileURLWithPath: url.deletingLastPathComponent().path)
        copyURL.appendPathComponent(fullName)
        
        if FileManager.default.fileExists(atPath: copyURL.path) {
            try? FileManager.default.removeItem(at: copyURL)
        }
        
        try? FileManager.default.copyItem(at: url, to: copyURL)
        
        self.url = copyURL        
    }
}

extension DocumentInteractionService: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        QLPreviewItemEq(url: url)
    }
    
    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        try? FileManager.default.removeItem(at: url)
    }
}

final class QLPreviewItemEq: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    
    init(url: URL) {
        previewItemURL = url
    }
}
