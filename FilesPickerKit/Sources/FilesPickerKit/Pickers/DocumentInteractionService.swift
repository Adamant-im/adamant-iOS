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
    private var urls: [URL] = []
    private var needToDelete = false
    
    public func openFile(files: [FileResult]) {
        self.urls = []
        files.forEach { file in
            let name = file.name ?? "UNKWNOW"
            let ext = file.extenstion ?? ""
            
            let fullName = name.contains(ext)
            ? name
            : "\(name).\(ext)"
            
            var copyURL = URL(fileURLWithPath: file.url.deletingLastPathComponent().path)
            copyURL.appendPathComponent(fullName)
            
            if FileManager.default.fileExists(atPath: copyURL.path) {
                try? FileManager.default.removeItem(at: copyURL)
            }
            
            try? FileManager.default.copyItem(at: file.url, to: copyURL)
            
            self.urls.append(copyURL)
        }
        
        needToDelete = true
    }
    
    public func openFile(url: URL) {
        self.urls = [url]
        needToDelete = false
    }
}

extension DocumentInteractionService: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        urls.count
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        QLPreviewItemEq(url: urls[index])
    }
    
    public func previewControllerDidDismiss(_ controller: QLPreviewController) {
        guard needToDelete else { return }
        urls.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
    }
}

final class QLPreviewItemEq: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    
    init(url: URL) {
        previewItemURL = url
    }
}
