//
//  FileResult.swift
//  
//
//  Created by Stanislav Jelezoglo on 06.03.2024.
//

import UIKit

public enum FileType {
    case image
    case video
    case other
}

public struct FileResult {
    public let url: URL
    public let type: FileType
    public let previewUrl: URL?
    public let preview: UIImage?
    public let size: Int64
    public let name: String?
    public let extenstion: String?
    
    public init(
        url: URL,
        type: FileType,
        preview: UIImage?,
        previewUrl: URL?,
        size: Int64,
        name: String?,
        extenstion: String?
    ) {
        self.url = url
        self.type = type
        self.previewUrl = previewUrl
        self.size = size
        self.name = name
        self.extenstion = extenstion
        self.preview = preview
    }
}
