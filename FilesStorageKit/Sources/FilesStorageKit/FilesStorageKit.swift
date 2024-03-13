// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import FilesNetworkManagerKit

public final class FilesStorageKit {
    private let adamantCore = NativeAdamantCore()
    private let networkFileManager = FilesNetworkManager()

    private var cachedImages: [String: UIImage] = [:]
    private var cachedFiles: [String: URL] = [:]
    private let imageExtensions = ["JPG", "JPEG", "PNG", "JPEG2000", "GIF", "WEBP", "TIF", "TIFF", "PSD", "RAW", "BMP", "HEIF", "INDD"]
    
    public init() { 
        try? loadCache()
    }
    
    public func getPreview(for id: String, type: String) -> UIImage {
        guard let data = cachedImages[id] else {
            return getPreview(for: type)
        }
        
        return data
    }
    
    public func isCached(_ id: String) -> Bool {
        cachedImages[id] != nil || cachedFiles[id] != nil
    }
    
    public func getFileData(
        with id: String,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String
    ) throws -> Data {
        if let image = cachedImages[id],
           let data = image.jpegData(compressionQuality: 1.0) {
            return data
        }
        
        if let url = cachedFiles[id],
           let encodedData = try? Data(contentsOf: url) {
            guard let decodedData = adamantCore.decodeData(
                encodedData,
                rawNonce: nonce,
                senderPublicKey: senderPublicKey,
                privateKey: recipientPrivateKey
            ) else {
                throw FileValidationError.fileNotFound
            }
            
            return decodedData
        }
        
        throw FileValidationError.fileNotFound
    }
    
    public func uploadFile(
        _ file: FileResult,
        recipientPublicKey: String,
        senderPrivateKey: String
    ) async throws -> (id: String, nonce: String) {
        defer {
            cacheImage(id: file.url.absoluteString, image: nil)
        }
        
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
        
        if imageExtensions.contains(file.extenstion?.lowercased() ?? .empty) {
            cacheImage(id: file.url.absoluteString, image: UIImage(data: encodedData))
        }
        
        let id = try await networkFileManager.uploadFiles(encodedData, type: .uploadCareApi)
        
        if imageExtensions.contains(file.extenstion?.lowercased() ?? .empty) {
            cacheImage(id: id, image: UIImage(data: data))
        }
        
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
        
        let fileExtension = fileType?.uppercased() ?? defaultFileType
        
        guard imageExtensions.contains(fileExtension) else {
            return try cacheFile(id: id, data: encodedData)
        }
        
        guard let decodedData = adamantCore.decodeData(
            encodedData,
            rawNonce: nonce,
            senderPublicKey: senderPublicKey,
            privateKey: recipientPrivateKey
        )
        else {
            throw FileValidationError.fileNotFound
        }
        
        cacheImage(id: id, image: UIImage(data: decodedData))
        return
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

    func cacheImage(id: String, image: UIImage?) {
        cachedImages[id] = image
    }

    private func getPreview(for type: String) -> UIImage {
        switch type.uppercased() {
        case "JPG", "JPEG", "PNG", "JPEG2000", "GIF", "WEBP", "TIF", "TIFF", "PSD", "RAW", "BMP", "HEIF", "INDD":
            return UIImage.asset(named: "file-image-box")!
        case "ZIP":
            return UIImage.asset(named: "file-zip-box")!
        case "PDF":
            return UIImage.asset(named: "file-pdf-box")!
        default:
            return UIImage.asset(named: "file-default-box")!
        }
    }
}

private let defaultFileType = ""
private let cachePath = "downloads"
