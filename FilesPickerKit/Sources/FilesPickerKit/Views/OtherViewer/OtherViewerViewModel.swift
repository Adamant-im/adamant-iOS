//
//  OtherViewerViewModel.swift
//
//
//  Created by Stanislav Jelezoglo on 12.03.2024.
//

import Foundation
import CommonKit
import SwiftUI

final class OtherViewerViewModel: ObservableObject {
    @Published var viewerShown: Bool = false
    @Published var caption: String
    @Published var size: Int64?
    @Published var fileUrl: URL
    @State var isShareSheetPresented = false
    
    private var copyURL: URL
    
    init(caption: String, size: Int64?, fileUrl: URL) {
        self.caption = caption
        self.size = size
        self.fileUrl = fileUrl
        self.copyURL = URL(fileURLWithPath: fileUrl.deletingLastPathComponent().path)
        copyURL.appendPathComponent(caption)
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file

        return formatter.string(fromByteCount: bytes)
    }
    
    func getCopyOfFile() throws -> URL {
        if FileManager.default.fileExists(atPath: copyURL.path) {
            try? FileManager.default.removeItem(at: copyURL)
        }
        
        try FileManager.default.copyItem(at: fileUrl, to: copyURL)
        return copyURL
    }
    
    func removeCopyOfFile() {
        try? FileManager.default.removeItem(at: copyURL)
    }
    
    func shareAction() {
//        if isMacOS {
//            try? saveFileToDownloadsFolder()
//            return
//        }
//        
//        isShareSheetPresented = true
        
        let documentInteractionController = UIDocumentInteractionController(url: fileUrl)
        documentInteractionController.presentPreview(animated: true)
    }
}

private extension OtherViewerViewModel {
    func saveFileToDownloadsFolder() throws {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        let fileURLInDownloads = downloadsURL.appendingPathComponent(caption)
        
        do {
            let data = try Data(contentsOf: fileUrl)
            
            try data.write(to: fileURLInDownloads)
        } catch {
            print("saving error=\(error)")
        }
    }
}
