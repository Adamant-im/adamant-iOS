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
                nonce: previewNonce
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
        senderPrivateKey: String
    ) async throws -> (id: String, nonce: String, idPreview: String?, noncePreview: String?) {
        let result = try await uploadFile(
            url: file.url,
            recipientPublicKey: recipientPublicKey,
            senderPrivateKey: senderPrivateKey
        )
        
        var resultPreview: UploadResult?
        
        if let url = file.previewUrl {
            resultPreview = try? await uploadFile(
                url: url,
                recipientPublicKey: recipientPublicKey,
                senderPrivateKey: senderPrivateKey
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
                nonce: previewNonce
            )
        }
        
        return try await downloadFile(
            id: id,
            storage: storage,
            fileType: fileType,
            senderPublicKey: senderPublicKey,
            recipientPrivateKey: recipientPrivateKey,
            nonce: nonce
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
        let url = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)
        
        try FileManager.default.removeItem(at: url)
        
        cachedFiles.removeAllObjects()
        cachedFilesUrl.removeAll()
    }
}

private extension FilesStorageKit {
    func downloadFile(
        id: String,
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String
    ) async throws {
        let decodedData = try await networkService.downloadFile(
            id: id,
            storage: storage,
            fileType: fileType,
            senderPublicKey: senderPublicKey,
            recipientPrivateKey: recipientPrivateKey,
            nonce: nonce
        )
        
        return try cacheFile(id: id, data: decodedData)
    }
    
    func uploadFile(
        url: URL,
        recipientPublicKey: String,
        senderPrivateKey: String
    ) async throws -> UploadResult {
        let result = try await networkService.uploadFile(
            url: url,
            recipientPublicKey: recipientPublicKey,
            senderPrivateKey: senderPrivateKey
        )
        
        try cacheFile(id: result.id, data: result.data)
        
        return (id: result.id, nonce: result.nonce)
    }
    
    func loadCache() throws {
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)

        let files = getFiles(at: folder)

        files.forEach { url in
            cachedFilesUrl[url.lastPathComponent] = url
            
            if let data = UIImage(contentsOfFile: url.path) {
                self.cachedFiles.setObject(data, forKey: url.lastPathComponent as NSString)
            }
        }
    }

    func getFiles(at url: URL) -> [URL] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        var subdirectoryNames: [URL] = []

        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return subdirectoryNames
        }

        for item in contents {
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) && !isDirectory.boolValue {
                subdirectoryNames.append(item)
            }
        }

        return subdirectoryNames
    }

    func cacheFile(id: String, data: Data) throws {
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileURL = folder.appendingPathComponent(id)

        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])

        cachedFilesUrl[id] = fileURL
        if let uiImage = UIImage(data: data) {
            cachedFiles.setObject(uiImage, forKey: id as NSString)
        }
    }
    
    private func getPreview(for type: String, url: URL?) -> URL? {
        switch type.uppercased() {
        case "JPG", "JPEG", "PNG", "GIF", "WEBP", "TIF", "TIFF", "BMP", "HEIF", "HEIC", "JP2":
            if let url = url {
                return url
            }
            
            return getLocalImageUrl(by: "file-image-box", withExtension: "jpg")
        case "MOV", "MP4":
            if let url = url {
                return url
            }
            
            return getLocalImageUrl(by: "file-image-box", withExtension: "jpg")
        default:
            return nil
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
