// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import SwiftUI

public final class FilesPickerKit: NSObject {
    public static let shared = FilesPickerKit()
    
    private let mediaPicker: FilePickerProtocol
    private let documentPicker: FilePickerProtocol
    private let documentInteration: DocumentInteractionProtocol
    
    public override init() {
        mediaPicker = MediaPickerService()
        documentPicker = DocumentPickerService()
        documentInteration = DocumentInteractionService()
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
        
    public func openFile(url: URL, name: String, size: Int64, ext: String) {
        let fullName = name.contains(ext)
        ? name
        : "\(name).\(ext)"
        
        var copyURL = URL(fileURLWithPath: url.deletingLastPathComponent().path)
        copyURL.appendPathComponent(fullName)
        
        if FileManager.default.fileExists(atPath: copyURL.path) {
            try? FileManager.default.removeItem(at: copyURL)
        }
        
        try? FileManager.default.copyItem(at: url, to: copyURL)
        
        documentInteration.open(url: copyURL, name: fullName) { [copyURL] in
            try? FileManager.default.removeItem(at: copyURL)
        }
    }
}

private extension FilesPickerKit {
    func validateFiles(_ files: [FileResult]) throws {
        guard files.count <= FilesConstants.maxFilesCount else {
            throw FileValidationError.tooManyFiles
        }
        
        for file in files {
            guard file.size <= FilesConstants.maxFileSize else {
                throw FileValidationError.fileSizeExceedsLimit
            }
        }
    }
}
