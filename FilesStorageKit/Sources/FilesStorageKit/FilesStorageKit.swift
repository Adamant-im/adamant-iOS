// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import FilesNetworkManagerKit

public final class FilesStorageKit {
    private let adamantCore = NativeAdamantCore()
    private let networkFileManager = FilesNetworkManager()
    private var cachedFiles: [String: URL] = [:]
    
    public init() { 
        try? loadCache()
    }
    
    public func getPreview(for id: String, type: String) -> URL? {
        getPreview(for: type, url: cachedFiles[id])
    }
    
    public func isCached(_ id: String) -> Bool {
        cachedFiles[id] != nil
    }
    
    public func getFileURL(with id: String) throws -> URL {
        guard let url = cachedFiles[id] else {
            throw FileValidationError.fileNotFound
        }
        
        return url
    }
    
    public func uploadFile(
        _ file: FileResult,
        recipientPublicKey: String,
        senderPrivateKey: String
    ) async throws -> (id: String, nonce: String) {
        _ = file.url.startAccessingSecurityScopedResource()
        
        let data = try Data(contentsOf: file.url)
        
        let encodedResult = adamantCore.encodeData(
            data,
            recipientPublicKey: recipientPublicKey,
            privateKey: senderPrivateKey
        )
        
        guard let encodedData = encodedResult?.data,
              let nonce = encodedResult?.nonce
        else {
            throw FileManagerError.cantEnctryptFile
        }
        
        let id = try await networkFileManager.uploadFiles(encodedData, type: .uploadCareApi)
        
        try cacheFile(id: id, data: data)
        
        file.url.stopAccessingSecurityScopedResource()
        return (id: id, nonce: nonce)
    }
    
    public func downloadFile(
        id: String,
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String
    ) async throws {
        let encodedData = try await networkFileManager.downloadFile(id, type: storage)
        
        guard let decodedData = adamantCore.decodeData(
            encodedData,
            rawNonce: nonce,
            senderPublicKey: senderPublicKey,
            privateKey: recipientPrivateKey
        )
        else {
            throw FileValidationError.fileNotFound
        }
        
        return try cacheFile(id: id, data: decodedData)
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

        let files = getFiles(at: folder)

        files.forEach { url in
            cachedFiles[url.lastPathComponent] = url
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

        cachedFiles[id] = fileURL
    }
    
    private func getPreview(for type: String, url: URL?) -> URL? {
        switch type.uppercased() {
        case "JPG", "JPEG", "PNG", "JPEG2000", "GIF", "WEBP", "TIF", "TIFF", "PSD", "RAW", "BMP", "HEIF", "INDD":
            if let url = url {
                return url
            }
            return getLocalImageUrl(by: "file-image-box", withExtension: "jpg")
        case "PDF":
            return getLocalImageUrl(by: "file-pdf-box", withExtension: "jpg")
        default:
            return getLocalImageUrl(by: "file-default-box", withExtension: "png")
        }
    }
}

private let defaultFileType = ""
private let cachePath = "downloads"
