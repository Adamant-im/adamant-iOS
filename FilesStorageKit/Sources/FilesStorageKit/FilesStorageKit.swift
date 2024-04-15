// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit

public final class FilesStorageKit {
    @Atomic private var cachedFilesUrl: [String: URL] = [:]
    private var cachedFiles: NSCache<NSString, UIImage> = NSCache()
    
    public init() {
        try? loadCache()
    }
    
    public func getPreview(for id: String, type: String) -> UIImage? {
        if let image = cachedFiles.object(forKey: id as NSString) {
            return image
        }
        
        guard let url = cachedFilesUrl[id],
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        
        cachedFiles.setObject(image, forKey: id as NSString)
        return image
    }
    
    public func isCached(_ id: String) -> Bool {
        cachedFilesUrl[id] != nil
    }
    
    public func getFileURL(with id: String) throws -> URL {
        guard let url = cachedFilesUrl[id] else {
            throw FileValidationError.fileNotFound
        }
        
        return url
    }
    
    public func cacheFile(
        id: String,
        url: URL,
        ownerId: String,
        recipientId: String
    ) throws {
        try cacheFile(
            with: id,
            localUrl: url,
            ownerId: ownerId,
            recipientId: recipientId
        )
    }
    
    public func cacheFile(
        id: String,
        data: Data,
        ownerId: String,
        recipientId: String
    ) throws {
        try cacheFile(
            with: id,
            data: data,
            ownerId: ownerId,
            recipientId: recipientId
        )
    }
    
    public func cacheTemporaryFile(url: URL) {
        cacheTemporaryFile(with: url)
    }
    
    public func getCacheSize() throws -> Int64 {
        let url = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)
        
        return try folderSize(at: url)
    }
    
    public func clearCache() throws {
        let cacheUrl = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)
        
        if FileManager.default.fileExists(
            atPath: cacheUrl.path
        ) {
            try FileManager.default.removeItem(at: cacheUrl)
        }
        
        try clearTempCache()
        
        cachedFiles.removeAllObjects()
        cachedFilesUrl.removeAll()
    }
    
    public func removeTempFiles(at urls: [URL]) {
        urls.forEach { url in
            guard FileManager.default.fileExists(
                atPath: url.path
            ) else { return }
            
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    public func clearTempCache() throws {
        let tempCacheUrl = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(tempCachePath)
        
        guard FileManager.default.fileExists(
            atPath: tempCacheUrl.path
        ) else { return }
        
        try FileManager.default.removeItem(at: tempCacheUrl)
    }
}

private extension FilesStorageKit {
    func loadCache() throws {
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)

        let files = getAllFiles(in: folder)
        
        files.forEach { url in
            cachedFilesUrl[url.lastPathComponent] = url
            
            if let data = UIImage(contentsOfFile: url.path) {
                self.cachedFiles.setObject(data, forKey: url.lastPathComponent as NSString)
            }
        }
    }

    func getAllFiles(in directoryURL: URL) -> [URL] {
        var fileURLs: [URL] = []
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: nil)
        
        while let fileURL = enumerator?.nextObject() as? URL {
            var isDirectory: ObjCBool = false
            let fileExist = fileManager.fileExists(
                atPath: fileURL.path,
                isDirectory: &isDirectory
            )
            
            if fileExist && !isDirectory.boolValue {
                fileURLs.append(fileURL)
            } else if fileExist && isDirectory.boolValue {
                fileURLs.append(contentsOf: getAllFiles(in: fileURL))
            }
        }
        
        return fileURLs
    }
    
    func cacheTemporaryFile(with url: URL) {
        cachedFilesUrl[url.absoluteString] = url
        if let uiImage = UIImage(contentsOfFile: url.path) {
            cachedFiles.setObject(uiImage, forKey: url.absoluteString as NSString)
        }
    }
    
    func cacheFile(
        with id: String,
        data: Data? = nil,
        localUrl: URL? = nil,
        ownerId: String,
        recipientId: String
    ) throws {
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("\(cachePath)/\(ownerId)/\(recipientId)")

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileURL = folder.appendingPathComponent(id)

        if let data = data {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
            
            cachedFilesUrl[id] = fileURL
            if let uiImage = UIImage(data: data) {
                cachedFiles.setObject(uiImage, forKey: id as NSString)
            }
        }
        
        if let url = localUrl {
            try FileManager.default.moveItem(at: url, to: fileURL)
            
            cachedFilesUrl[id] = fileURL
            cachedFilesUrl[url.absoluteString] = fileURL
            if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                cachedFiles.setObject(uiImage, forKey: id as NSString)
                cachedFiles.setObject(uiImage, forKey: url.absoluteString as NSString)
            }
        }
    }
    
    func folderSize(at url: URL) throws -> Int64 {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileValidationError.fileNotFound
        }
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            throw FileValidationError.fileNotFound
        }
        
        var folderSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    folderSize += fileSize
                }
            } catch { }
        }
        
        return folderSize
    }
}

private let cachePath = "downloads"
private let tempCachePath = "downloads/cache"
