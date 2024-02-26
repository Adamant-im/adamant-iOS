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
    var isCached: Bool
    
    static let `default` = Self(
        file: .init([:]),
        previewData: Data(),
        isDownloading: false,
        isCached: false
    )
}
