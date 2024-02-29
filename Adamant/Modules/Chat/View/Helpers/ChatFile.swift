//
//  ChatFile.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

struct ChatFile: Equatable, Hashable {
    var file: RichMessageFile.File
    var previewData: Data
    var isDownloading: Bool
    var isUploading: Bool
    var isCached: Bool
    var storage: String
    
    static let `default` = Self(
        file: .init([:]),
        previewData: Data(),
        isDownloading: false,
        isUploading: false,
        isCached: false,
        storage: .empty
    )
}
