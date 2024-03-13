//
//  OtherViewerViewModel.swift
//
//
//  Created by Stanislav Jelezoglo on 12.03.2024.
//

import Foundation

final class OtherViewerViewModel: ObservableObject {
    @Published var viewerShown: Bool = false
    @Published var caption: String?
    @Published var size: Int64?
    @Published var data: Data
    
    init(caption: String?, size: Int64?, data: Data) {
        self.caption = caption
        self.size = size
        self.data = data
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file

        return formatter.string(fromByteCount: bytes)
    }
}
