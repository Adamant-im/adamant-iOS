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
    
    private let networkFileManager: NetworkFileManagerProtocol = NetworkFileManager()
    
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
    
    public func getPreview(for id: String, type: String) -> Data {
        guard let data = cachedImages[id]?.jpegData(compressionQuality: 1.0)
        else {
            return UIImage.asset(named: "file-jpg-box")?.jpegData(compressionQuality: 1.0) ?? Data()
        }
        
        return data
    }
    
    public func isCached(_ id: String) -> Bool {
        cachedImages[id] != nil
    }
    
    public func uploadFile(_ data: Data, type: NetworkFileProtocolType) async throws -> String {
        try await networkFileManager.uploadFiles(data, type: type)
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
}
