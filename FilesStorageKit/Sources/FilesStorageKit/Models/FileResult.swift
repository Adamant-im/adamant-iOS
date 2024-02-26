//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 19.02.2024.
//

import Foundation
import UIKit

public enum FileType {
    case image
    case video
    case other
}

public struct FileResult {
    public let url: URL
    public let type: FileType
    public let preview: UIImage?
    public let size: Int64
    public let name: String?
}
