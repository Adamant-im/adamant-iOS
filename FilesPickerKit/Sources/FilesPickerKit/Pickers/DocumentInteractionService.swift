//
//  DocumentInteractionService.swift
//
//
//  Created by Stanislav Jelezoglo on 14.03.2024.
//

import UIKit
import CommonKit
import SwiftUI
import WebKit
import QuickLook

public final class DocumentInteractionService: NSObject {
    private var items: ItemsList = .default
    private var itemsToBeRemoved: ItemsList = .default
    
    public func openFile(files: [FileResult]) {
        let urls = files.map { file in
            let name = file.name ?? "Unknown"
            let ext = file.extenstion
            
            let fullName = [name, ext]
                .compactMap { $0 }
                .joined(separator: ".")
            
            var copyURL = URL(fileURLWithPath: file.url.deletingLastPathComponent().path)
            copyURL.appendPathComponent(fullName)
            
            if !FileManager.default.fileExists(atPath: copyURL.path) {
                if let data = file.data {
                    try? data.write(to: copyURL, options: [.atomic, .completeFileProtection])
                } else {
                    try? FileManager.default.copyItem(at: file.url, to: copyURL)
                }
            }
            
            return copyURL
        }
        
        items = .init(urls: urls)
    }
}

extension DocumentInteractionService: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        items.urls.count
    }
    
    public func previewController(
        _ controller: QLPreviewController,
        previewItemAt index: Int
    ) -> QLPreviewItem {
        QLPreviewItemEq(url: items.urls[safe: index])
    }
    
    public func previewController(
        _: QLPreviewController,
        transitionViewFor _: QLPreviewItem
    ) -> UIView? { .init() }
    
    public func previewControllerWillDismiss(_: QLPreviewController) {
        itemsToBeRemoved = items
    }
    
    public func previewControllerDidDismiss(_: QLPreviewController) {
        // if new items presented before dismissing the previous ones: do not delete everything
        // because some items could be presenting again
        let urlToDelete = itemsToBeRemoved.id == items.id
            ? items.urls
            : Set(itemsToBeRemoved.urls).subtracting(.init(items.urls)).map { $0 }
        
        urlToDelete.forEach { try? FileManager.default.removeItem(at: $0) }
    }
}

private extension DocumentInteractionService {
    struct ItemsList {
        let id: UUID = .init()
        let urls: [URL]
        
        static let `default` = Self(urls: .init())
    }
    
    final class QLPreviewItemEq: NSObject, QLPreviewItem {
        let previewItemURL: URL?
        
        init(url: URL?) {
            previewItemURL = url
        }
    }
}
