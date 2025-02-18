//
//  FileResult.swift
//  
//
//  Created by Stanislav Jelezoglo on 06.03.2024.
//

import UIKit

public enum FileType: Sendable {
    case image
    case video
    case other
    
    public var isMedia: Bool {
        switch self {
        case .image, .video:
            return true
        case .other:
            return false
        }
    }
}

public extension FileType {
    init?(mimeType: String) {
        if mimeType.hasPrefix("image/") {
            self = .image
        } else if mimeType.hasPrefix("video/") {
            self = .video
        } else {
            self = .other
        }
    }
    
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

public struct FileResult: Sendable {
    public let assetId: String?
    public let url: URL
    public let type: FileType
    public let previewUrl: URL?
    public let preview: UIImage?
    public let previewExtension: String?
    public let size: Int64
    public let name: String?
    public let extenstion: String?
    public let resolution: CGSize?
    public let data: Data?
    public let duration: Float64?
    public let mimeType: String?
    
    public init(
        assetId: String? = nil,
        url: URL,
        type: FileType,
        preview: UIImage?,
        previewUrl: URL?,
        previewExtension: String?,
        size: Int64,
        name: String?,
        extenstion: String?,
        resolution: CGSize?,
        data: Data? = nil,
        duration: Float64? = nil,
        mimeType: String? = nil
    ) {
        self.assetId = assetId
        self.url = url
        self.type = type
        self.previewUrl = previewUrl
        self.previewExtension = previewExtension
        self.size = size
        self.name = name
        self.extenstion = extenstion
        self.preview = preview
        self.resolution = resolution
        self.data = data
        self.duration = duration
        self.mimeType = mimeType
    }
}

public extension FileResult {
    init(
        assetId: String? = nil,
        url: URL,
        type: FileType,
        preview: UIImage?,
        previewUrl: URL?,
        previewExtension: String?,
        size: Int64,
        namePossiblyWithExtension: String,
        extenstion: String?,
        resolution: CGSize?,
        data: Data? = nil,
        duration: Float64? = nil,
        mimeType: String? = nil
    ) {
        let nameWithExtension = namePossiblyWithExtension.separateFileExtension()
        
        let name = nameWithExtension.extension == extenstion
            ? nameWithExtension.name
            : namePossiblyWithExtension
        
        self.init(
            assetId: assetId,
            url: url,
            type: type,
            preview: preview,
            previewUrl: previewUrl,
            previewExtension: previewExtension,
            size: size,
            name: name,
            extenstion: extenstion,
            resolution: resolution,
            data: data,
            duration: duration,
            mimeType: mimeType
        )
    }
}
