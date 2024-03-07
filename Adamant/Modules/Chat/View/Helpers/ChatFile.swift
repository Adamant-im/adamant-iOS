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
    var previewData: UIImage?
    var isDownloading: Bool
    var isUploading: Bool
    var isCached: Bool
    var storage: String
    var nonce: String
    var isFromCurrentSender: Bool
    
    static let `default` = Self(
        file: .init([:]),
        previewData: nil,
        isDownloading: false,
        isUploading: false,
        isCached: false,
        storage: .empty,
        nonce: .empty,
        isFromCurrentSender: false
    )
}
