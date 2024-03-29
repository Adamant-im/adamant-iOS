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

public extension FileType {
    init?(raw: String) {
        switch raw.uppercased() {
        case "JPG", "JPEG", "PNG", "GIF", "WEBP", "TIF", "TIFF", "BMP", "HEIF", "HEIC", "JP2":
            self = .image
        case "MOV", "MP4":
            self = .video
        default: self = .other
        }
    }
}

public struct FileResult {
    public let url: URL
    public let type: FileType
    public let previewUrl: URL?
    public let preview: UIImage?
    public let size: Int64
    public let name: String?
    public let extenstion: String?
    public let resolution: CGSize?
    
    public init(
        url: URL,
        type: FileType,
        preview: UIImage?,
        previewUrl: URL?,
        size: Int64,
        name: String?,
        extenstion: String?,
        resolution: CGSize?
    ) {
        self.url = url
        self.type = type
        self.previewUrl = previewUrl
        self.size = size
        self.name = name
        self.extenstion = extenstion
        self.preview = preview
        self.resolution = resolution
    }
}
