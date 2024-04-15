//
//  FilesStorageProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit
import FilesStorageKit

protocol FilesStorageProtocol {
    func getPreview(for id: String, type: String) -> UIImage?
    
    func isCached(_ id: String) -> Bool
    
    func getFileURL(with id: String) throws -> URL
    
    func cacheFile(
        id: String,
        url: URL,
        ownerId: String,
        recipientId: String
    ) throws
    
    func cacheFile(
        id: String,
        data: Data,
        ownerId: String,
        recipientId: String
    ) throws
    
    func cacheTemporaryFile(url: URL)
    
    func getCacheSize() throws -> Int64
    
    func clearCache() throws
    
    func clearTempCache() throws
    
    func removeTempFiles(at urls: [URL])
}

extension FilesStorageKit: FilesStorageProtocol { }
