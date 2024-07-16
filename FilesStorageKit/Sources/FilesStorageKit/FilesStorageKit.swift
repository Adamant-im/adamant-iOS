// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import Combine

public final class FilesStorageKit: FilesStorageProtocol {
    public struct File {
        public let id: String
        public let isEncrypted: Bool
        public let url: URL
        public let fileType: FileType
        public let isPreview: Bool
    }
    
    @Atomic private var cachedFiles: [String: File] = [:]
    private var cachedImages: NSCache<NSString, UIImage> = NSCache()
    private let maxCachedFilesToLoad = 100
    private let encryptedFileExtension = "encFhj"
    private let previewFileExtension = "prvAIFE"
    
    public init() {
        try? loadCache()
    }
    
    public func getPreview(for id: String) -> UIImage? {
        guard !id.isEmpty else { return nil }
        
        if let image = cachedImages.object(forKey: id as NSString) {
            return image
        }
        
        return nil
    }
    
    public func cacheImageToMemoryIfNeeded(id: String, data: Data) -> UIImage? {
        guard let image = UIImage(data: data),
              cachedImages.object(forKey: id as NSString) == nil
        else {
            return nil
        }
        
        cachedImages.setObject(image, forKey: id as NSString)
        return image
    }
    
    public func isCachedInMemory(_ id: String) -> Bool {
        guard !id.isEmpty else { return false }
        
        return cachedImages.object(forKey: id as NSString) != nil
    }
    
    public func isCachedLocally(_ id: String) -> Bool {
        cachedFiles[id] != nil
    }
    
    public func getFile(with id: String) throws -> File {
        guard let file = cachedFiles[id] else {
            throw FileValidationError.fileNotFound
        }
        
        return file
    }
    
    public func getFileURL(with id: String) throws -> URL {
        try getFile(with: id).url
    }
    
    public func cacheFile(
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
    ) throws {
        try saveFileLocally(
            with: id,
            fileExtension: fileExtension,
            data: saveEncrypted ? encodedData : decodedData,
            localUrl: url,
            ownerId: ownerId,
            recipientId: recipientId,
            isEncrypted: saveEncrypted,
            fileType: fileType,
            isPreview: isPreview
        )
        
        guard fileType == .image, isPreview else { return }
        cacheFileToMemory(data: decodedData, id: id)
        
        if let url = url {
            cacheFileToMemory(data: decodedData, id: url.absoluteString)
        }
    }
    
    public func cacheTemporaryFile(
        url: URL,
        isEncrypted: Bool,
        fileType: FileType,
        isPreview: Bool
    ) {
        cacheTemporaryFile(
            with: url,
            isEncrypted: isEncrypted,
            fileType: fileType,
            isPreview: isPreview
        )
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
        
        cachedImages.removeAllObjects()
        cachedFiles.removeAll()
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
    
    public func getTempUrl(for image: UIImage?, name: String) throws -> URL {
        guard let data = image?.jpegData(compressionQuality: FilesConstants.previewCompressQuality) else {
            throw FileValidationError.fileNotFound
        }
        
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(tempCachePath)

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileURL = folder.appendingPathComponent(name)

        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        return fileURL
    }
    
    public func copyFileToTempCache(from url: URL) throws -> URL {
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        _ = url.startAccessingSecurityScopedResource()
        
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(tempCachePath)
        
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )
        
        let targetURL = folder.appendingPathComponent(String.random(length: 6) + url.lastPathComponent)
        
        guard targetURL != url else { return url }
        
        if FileManager.default.fileExists(atPath: targetURL.path) {
            try FileManager.default.removeItem(at: targetURL)
        }
        
        try FileManager.default.copyItem(at: url, to: targetURL)
        
        return targetURL
    }
    
    public func getFileSize(from fileURL: URL) throws -> Int64 {
        defer {
            fileURL.stopAccessingSecurityScopedResource()
        }
        
        _ = fileURL.startAccessingSecurityScopedResource()
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            guard let fileSize = fileAttributes[.size] as? Int64 else {
                throw FileValidationError.fileNotFound
            }
            
            return fileSize
        } catch {
            throw error
        }
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
        
        var previewFiles: [File] = []
        
        files.forEach { url in
            let result = fileNameAndExtension(from: url)
            let isEncrypted = result.extensions.contains(encryptedFileExtension)
            let isPreview = result.extensions.contains(previewFileExtension)
            
            let file = File(
                id: result.name,
                isEncrypted: isEncrypted,
                url: url,
                fileType: FileType(raw: result.extensions.first ?? .empty) ?? .other,
                isPreview: isPreview
            )
            cachedFiles[result.name] = file
            
            if isPreview, !isEncrypted {
                previewFiles.append(file)
            }
        }
        
        previewFiles.prefix(maxCachedFilesToLoad).forEach { file in
            if let data = UIImage(contentsOfFile: file.url.path) {
                cachedImages.setObject(data, forKey: file.id as NSString)
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
        
        return Array(Set(fileURLs))
    }
    
    func cacheTemporaryFile(
        with url: URL,
        isEncrypted: Bool,
        fileType: FileType,
        isPreview: Bool
    ) {
        let file = File(
            id: url.absoluteString,
            isEncrypted: isEncrypted,
            url: url,
            fileType: fileType,
            isPreview: isPreview
        )
        $cachedFiles.mutate { $0[file.id] = file }
        
        if fileType == .image,
           isPreview,
           let uiImage = UIImage(contentsOfFile: url.path) {
            cachedImages.setObject(uiImage, forKey: file.id as NSString)
        }
    }
    
    func cacheFileToMemory(data: Data, id: String) {
        guard let uiImage = UIImage(data: data) else { return }
        
        cachedImages.setObject(uiImage, forKey: id as NSString)
    }
    
    func saveFileLocally(
        with id: String,
        fileExtension: String,
        data: Data? = nil,
        localUrl: URL? = nil,
        ownerId: String,
        recipientId: String,
        isEncrypted: Bool,
        fileType: FileType,
        isPreview: Bool
    ) throws {
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("\(cachePath)/\(ownerId)/\(recipientId)")

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let mainExtension = !fileExtension.isEmpty
        ? ".\(fileExtension)"
        : .empty
        
        let additionalExtension = isPreview
        ? ".\(previewFileExtension)"
        : .empty
        
        let fileName = isEncrypted
        ? "\(id)\(mainExtension)\(additionalExtension).\(encryptedFileExtension)"
        : "\(id)\(mainExtension)\(additionalExtension)"
        
        let fileURL = folder.appendingPathComponent(fileName)
        let file = File(
            id: id,
            isEncrypted: isEncrypted,
            url: fileURL,
            fileType: fileType,
            isPreview: isPreview
        )
        
        if let data = data {
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        }
        
        if let url = localUrl {
            try FileManager.default.removeItem(at: url)
            $cachedFiles.mutate { $0[url.absoluteString] = file }
        }
        
        $cachedFiles.mutate { $0[id] = file }
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
    
    func fileNameAndExtension(from url: URL) -> (name: String, extensions: [String]) {
        let filename = url.lastPathComponent
        let nameComponents = filename.components(separatedBy: ".")
        
        guard nameComponents.count > 1,
              let name = nameComponents.first
        else {
            return (filename.replacingOccurrences(of: ".", with: ""), [])
        }
        
        return (name, Array(nameComponents.dropFirst()))
    }
}

private let cachePath = "downloads"
private let tempCachePath = "downloads/cache"
