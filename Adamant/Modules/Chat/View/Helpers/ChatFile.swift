//
//  ChatFile.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import UIKit

struct ChatFile: Equatable, Hashable {
    var file: RichMessageFile.File
    var previewImage: UIImage?
    var isDownloading: Bool
    var isUploading: Bool
    var isCached: Bool
    var storage: String
    var nonce: String
    var isFromCurrentSender: Bool
    var fileType: FileType
    var progress: Int
    var isPreviewDownloadAllowed: Bool
    var isFullMediaDownloadAllowed: Bool
    
    var isBusy: Bool {
        return isDownloading || isUploading
    }
    
    static let `default` = Self(
        file: .init([:]),
        previewImage: nil,
        isDownloading: false,
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
