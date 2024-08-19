//
//  FilesStorageProtocol.swift
//
//
//  Created by Stanislav Jelezoglo on 21.05.2024.
//

import UIKit
import CommonKit

public protocol FilesStorageProtocol {
    func cacheImageToMemoryIfNeeded(id: String, data: Data) -> UIImage?
    
    func getPreview(for id: String) -> UIImage?
    
    func isCachedLocally(_ id: String) -> Bool
    
    func isCachedInMemory(_ id: String) -> Bool
    
    func getFileURL(with id: String) -> FileStorageServiceResult<URL>
    
    func getFile(with id: String) -> FileStorageServiceResult<FilesStorageKit.File>
    
    func cacheTemporaryFile(
        url: URL,
        isEncrypted: Bool,
        fileType: FileType,
        isPreview: Bool
    )
    
    func cacheFile(
        id: String,
        fileExtension: String,
        url: URL?,
        decodedData: Data,
        encodedData: Data,
        ownerId: String,
        recipientId: String,
        saveEncrypted: Bool,
        fileType: FileType,
        isPreview: Bool
    ) throws
    
    func getCacheSize() -> FileStorageServiceResult<Int64>
    
    func clearCache() throws
    
    func clearTempCache() throws
    
    func removeTempFiles(at urls: [URL])
    
    func getTempUrl(for image: UIImage?, name: String) throws -> URL
    
    func copyFileToTempCache(from url: URL) throws -> URL
    
    func getFileSize(from fileURL: URL) -> FileStorageServiceResult<Int64>
}
