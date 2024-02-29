// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit

public final class FilesStorageKit {
    public static let shared = FilesStorageKit()
    
    private let window = TransparentWindow(frame: UIScreen.main.bounds)
    private let mediaPicker: FilePickerProtocol
    private let documentPicker: FilePickerProtocol
    private var cachedImages: [String: UIImage] = [:]
    private var cachedFiles: [String: URL] = [:]
    
    private let networkFileManager: NetworkFileManagerProtocol = NetworkFileManager()
    private let imageExtensions = ["jpg", "png", "jpeg"]
    
    public init() {
        mediaPicker = MediaPickerService()
        documentPicker = DocumentPickerService()
    }
    
    @MainActor
    public func presentImagePicker() async throws -> [FileResult] {
        try await withUnsafeThrowingContinuation { continuation in
            mediaPicker.startPicker(
                window: window
            ) { [weak self] data in
                do {
                    try self?.validateFiles(data.map { $0.url })
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }
    
    @MainActor
    public func presentDocumentPicker() async throws -> [FileResult] {
        try await withUnsafeThrowingContinuation { continuation in
            documentPicker.startPicker(
                window: window
            ) { [weak self] data in
                do {
                    try self?.validateFiles(data.map { $0.url })
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }
    
    public func cacheImage(id: String, image: UIImage) {
        cachedImages[id] = image
    }
    
    public func getCachedImage(id: String) -> UIImage? {
        cachedImages[id]
    }
    
    public func getCachedFile(id: String) -> URL? {
        cachedFiles[id]
    }
    
    public func getPreview(for id: String, type: String) -> Data {
        guard let data = cachedImages[id]?.jpegData(compressionQuality: 1.0)
        else {
            return UIImage.asset(named: "file-default-box")?.jpegData(compressionQuality: 1.0) ?? Data()
        }
        
        return data
    }
    
    public func isCached(_ id: String) -> Bool {
        cachedImages[id] != nil || cachedFiles[id] != nil
    }
    
    public func uploadFile(_ file: FileResult) async throws -> String {
        _ = file.url.startAccessingSecurityScopedResource()
        
        let data = try Data(contentsOf: file.url)
        
        if imageExtensions.contains(file.extenstion?.lowercased() ?? .empty) {
            cacheImage(id: file.url.absoluteString, image: UIImage(data: data) ?? UIImage())
        }
        
        let id = try await networkFileManager.uploadFiles(data, type: .uploadCareApi)
        
        if imageExtensions.contains(file.extenstion?.lowercased() ?? .empty) {
            cacheImage(id: id, image: UIImage(data: data) ?? UIImage())
        }
        
        file.url.stopAccessingSecurityScopedResource()
        return id
    }
    
    public func cacheFile(
        id: String,
        storage: String,
        fileType: String?
    ) async throws -> Data {
        let data = try await networkFileManager.downloadFile(id, type: storage)
        
        if imageExtensions.contains(fileType?.lowercased() ?? defaultFileType) {
            cacheImage(id: id, image: UIImage(data: data) ?? UIImage())
        } else {
            try cacheFile(id: id, data: data)
        }
        
        return data
    }
}

private extension FilesStorageKit {
    func validateFiles(_ fileURLs: [URL]) throws {
        guard fileURLs.count <= Constants.maxFilesCount else {
            throw FileValidationError.tooManyFiles
        }

        for fileURL in fileURLs {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            
            guard let fileSize = fileAttributes[.size] as? Int64 else {
                throw FileValidationError.fileNotFound
            }

            guard fileSize <= Constants.maxFileSize else {
                throw FileValidationError.fileSizeExceedsLimit
            }
        }
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
}

private let defaultFileType = ""
private let cachePath = "downloads"
