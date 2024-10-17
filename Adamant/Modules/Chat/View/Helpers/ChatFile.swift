//
//  ChatFile.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import UIKit

struct DownloadStatus: Hashable {
    var isPreviewDownloading: Bool
    var isOriginalDownloading: Bool
    
    static let `default` = Self(
        isPreviewDownloading: false,
        isOriginalDownloading: false
    )
}

struct ChatFile: Equatable, Hashable, @unchecked Sendable {
    var file: RichMessageFile.File
    var previewImage: UIImage?
    var downloadStatus: DownloadStatus
    var isUploading: Bool
    var isCached: Bool
    var storage: String
    var nonce: String
    var isFromCurrentSender: Bool
    var fileType: FileType
    var progress: Int?
    var isPreviewDownloadAllowed: Bool
    var isFullMediaDownloadAllowed: Bool
    
    var isBusy: Bool {
        isDownloading
        || isUploading
    }
    
    var isDownloading: Bool {
        downloadStatus.isOriginalDownloading
        || downloadStatus.isPreviewDownloading
    }
    
    static var `default`: Self {
        Self(
            file: .init([:]),
            previewImage: nil,
            downloadStatus: .default,
            isUploading: false,
            isCached: false,
            storage: .empty,
            nonce: .empty,
            isFromCurrentSender: false,
            fileType: .other,
            progress: .zero,
            isPreviewDownloadAllowed: false,
            isFullMediaDownloadAllowed: false
        )
    }
}
