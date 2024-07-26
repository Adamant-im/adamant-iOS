//
//  FilesConstants.swift
//  
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//

import Foundation

public final class FilesConstants {
    public static let maxFilesCount = 10
    public static let maxFileSize: Int64 = 250 * 1024 * 1024
    public static let previewSize: CGSize = .init(squareSize: 400)
    public static let previewVideoSize: CGSize = .init(squareSize: 700)
    public static let previewTag: String = "preview_"
    public static let previewCompressQuality: CGFloat = 0.8
}
