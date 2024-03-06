// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit

public final class FilesPickerKit {
    public static let shared = FilesPickerKit()
    
    private let mediaPicker: FilePickerProtocol
    private let documentPicker: FilePickerProtocol
    
    public init() {
        mediaPicker = MediaPickerService()
        documentPicker = DocumentPickerService()
    }
    
    @MainActor
    public func presentImagePicker() async throws -> [FileResult] {
        try await withUnsafeThrowingContinuation { continuation in
            mediaPicker.startPicker { [weak self] data in
                do {
                    try self?.validateFiles(data)
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
            documentPicker.startPicker { [weak self] data in
                do {
                    try self?.validateFiles(data)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }
}

private extension FilesPickerKit {
    func validateFiles(_ files: [FileResult]) throws {
        guard files.count <= Constants.maxFilesCount else {
            throw FileValidationError.tooManyFiles
        }
        
        for file in files {
            guard file.size <= Constants.maxFileSize else {
                throw FileValidationError.fileSizeExceedsLimit
            }
        }
    }
}
