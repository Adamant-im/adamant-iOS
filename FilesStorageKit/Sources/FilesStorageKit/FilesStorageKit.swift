// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import FilesNetworkManagerKit

public final class FilesStorageKit {
    typealias UploadResult = (id: String, nonce: String)

    private let adamantCore = NativeAdamantCore()
    private let networkFileManager = FilesNetworkManager()
    private let networkService = NetworkService()
    private let taskQueue = TaskQueue<Void>(maxTasks: 5)
    
    @Atomic private var cachedFilesUrl: [String: URL] = [:]
    private var cachedFiles: NSCache<NSString, UIImage> = NSCache()
    
    public init() {
        try? loadCache()
    }
    
    public func cachePreview(
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        ownerId: String,
        recipientId: String,
        previewId: String,
        previewNonce: String
    ) async throws {
        await taskQueue.enqueue {
            try? await self.downloadFile(
                id: previewId,
                storage: storage,
                fileType: fileType,
                senderPublicKey: senderPublicKey,
                recipientPrivateKey: recipientPrivateKey,
                nonce: previewNonce,
                ownerId: ownerId,
                recipientId: recipientId
            )
        }
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
    
    public func uploadFile(
        _ file: FileResult,
        recipientPublicKey: String,
        senderPrivateKey: String,
        ownerId: String,
        recipientId: String
    ) async throws -> (id: String, nonce: String, idPreview: String?, noncePreview: String?) {
        let result = try await uploadFile(
            url: file.url,
            recipientPublicKey: recipientPublicKey,
            senderPrivateKey: senderPrivateKey,
            ownerId: ownerId,
            recipientId: recipientId
        )
        
        var resultPreview: UploadResult?
        
        if let url = file.previewUrl {
            resultPreview = try? await uploadFile(
                url: url,
                recipientPublicKey: recipientPublicKey,
                senderPrivateKey: senderPrivateKey,
                ownerId: ownerId,
                recipientId: recipientId
            )
        }
        
        return (id: result.id, nonce: result.nonce, idPreview: resultPreview?.id, noncePreview: resultPreview?.nonce)
    }
    
    public func downloadFile(
        id: String,
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        ownerId: String,
        recipientId: String,
        nonce: String,
        previewId: String?,
        previewNonce: String?
    ) async throws {
        if let previewId = previewId,
           let previewNonce = previewNonce {
            try? await downloadFile(
                id: previewId,
                storage: storage,
                fileType: fileType,
                senderPublicKey: senderPublicKey,
                recipientPrivateKey: recipientPrivateKey,
                nonce: previewNonce,
                ownerId: ownerId,
                recipientId: recipientId
            )
        }
        
        return try await downloadFile(
            id: id,
            storage: storage,
            fileType: fileType,
            senderPublicKey: senderPublicKey,
            recipientPrivateKey: recipientPrivateKey,
            nonce: nonce,
            ownerId: ownerId,
            recipientId: recipientId
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
        
        cachedFiles.removeAllObjects()
        cachedFilesUrl.removeAll()
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
    func downloadFile(
        id: String,
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String,
        ownerId: String,
        recipientId: String
    ) async throws {
        let decodedData = try await networkService.downloadFile(
            id: id,
            storage: storage,
            fileType: fileType,
            senderPublicKey: senderPublicKey,
            recipientPrivateKey: recipientPrivateKey,
            nonce: nonce
        )
        
        return try cacheFile(
            id: id,
            data: decodedData,
            ownerId: ownerId,
            recipientId: recipientId
        )
    }
    
    func uploadFile(
        url: URL,
        recipientPublicKey: String,
        senderPrivateKey: String,
        ownerId: String,
        recipientId: String
    ) async throws -> UploadResult {
        let result = try await networkService.uploadFile(
            url: url,
            recipientPublicKey: recipientPublicKey,
            senderPrivateKey: senderPrivateKey
        )
        
        try cacheFile(
            id: result.id,
            localUrl: url,
            ownerId: ownerId,
            recipientId: recipientId
        )
        
        return (id: result.id, nonce: result.nonce)
    }
    
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
    
    func cacheFile(
        id: String,
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
