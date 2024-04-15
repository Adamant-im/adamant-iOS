// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import SwiftUI
import AVFoundation
import QuickLook

final class FilesPickerKitHelper {
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
    
    func getUrl(for image: UIImage?, name: String) throws -> URL {
        guard let data = image?.jpegData(compressionQuality: FilesConstants.previewCompressQuality) else {
            throw FileValidationError.fileNotFound
        }
        
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileURL = folder.appendingPathComponent(name)

        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        return fileURL
    }
    
    func copyFile(from url: URL) throws -> URL {
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        _ = url.startAccessingSecurityScopedResource()
        
        let folder = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(cachePath)
        
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let newSize = getPreviewSize(from: image.size)
        
        return image.imageResized(to: newSize)
    }
    
    func getOriginalSize(for url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(
            withMediaType: AVMediaType.video
        ).first
        else { return nil }
        
        let naturalSize = track.naturalSize.applying(track.preferredTransform)
        
        return .init(width: abs(naturalSize.width), height: abs(naturalSize.height))
    }
    
    func getThumbnailImage(
        forUrl url: URL,
        originalSize: CGSize?
    ) async throws -> UIImage? {
        var thumbnailSize: CGSize?
        
        if let size = originalSize {
            thumbnailSize = getPreviewSize(from: size)
        }
        
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: thumbnailSize ?? FilesConstants.previewSize,
            scale: 1.0,
            representationTypes: .thumbnail
        )
        
        let image = try await QLThumbnailGenerator.shared.generateBestRepresentation(
            for: request
        ).uiImage
        
        return image
    }
    
    func getFileSize(from fileURL: URL) throws -> Int64 {
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
    
    func getFileResult(for url: URL) throws -> FileResult {
        let newUrl = try copyFile(from: url)
        let preview = getPreview(for: newUrl)
        let fileSize = try getFileSize(from: newUrl)
        return FileResult(
            assetId: url.absoluteString,
            url: newUrl,
            type: .other,
            preview: preview.image,
            previewUrl: preview.url,
            size: fileSize,
            name: url.lastPathComponent,
            extenstion: url.pathExtension,
            resolution: preview.resolution
        )
    }
    
    @MainActor
    func getUrlConforms(
        to type: UTType,
        for itemProvider: NSItemProvider
    ) async throws -> URL {
        for identifier in itemProvider.registeredTypeIdentifiers {
            guard let utType = UTType(identifier), utType.conforms(to: type) else {
                continue
            }
            
            do {
                return try await getFileURL(by: identifier, itemProvider: itemProvider)
            } catch {
                continue
            }
        }
        
        throw FilePickersError.cantSelectFile(itemProvider.suggestedName ?? .empty)
    }
    
    @MainActor
    func getUrl(for itemProvider: NSItemProvider) async throws -> URL {
        for type in itemProvider.registeredTypeIdentifiers {
            do {
                return try await getFileURL(by: type, itemProvider: itemProvider)
            } catch {
                continue
            }
        }
        
        throw FileValidationError.fileNotFound
    }
    
    @MainActor
    func getFileURL(
        by type: String,
        itemProvider: NSItemProvider
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    if let targetURL = try? self.copyFile(from: url) {
                        continuation.resume(returning: targetURL)
                    } else {
                        continuation.resume(throwing: FileValidationError.fileNotFound)
                    }
                } else {
                    continuation.resume(throwing: FileValidationError.fileNotFound)
                }
            }
        }
    }
}

private extension FilesPickerKitHelper {
    func getPreviewSize(from originalSize: CGSize?) -> CGSize {
        guard let size = originalSize else { return FilesConstants.previewSize }
        
        let width = abs(size.width)
        let height = abs(size.height)
        
        let widthRatio  = FilesConstants.previewSize.width  / width
        let heightRatio = FilesConstants.previewSize.height / height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(
                width: width * heightRatio,
                height: height * heightRatio
            )
        } else {
            newSize = CGSize(
                width: width * widthRatio,
                height: height * widthRatio
            )
        }
        
        return newSize
    }
    
    func isFileType(format: UTType, atURL fileURL: URL) -> Bool {
        var mimeType: String?
        
        let pathExtension = fileURL.pathExtension
        if let type = UTType(filenameExtension: pathExtension) {
            mimeType = type.preferredMIMEType
        }
        
        guard let mimeType = mimeType else { return false }
        
        return UTType(mimeType: mimeType)?.conforms(to: format) ?? false
    }
    
    func getPreview(for url: URL) -> (image: UIImage?, url: URL?, resolution: CGSize?) {
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        _ = url.startAccessingSecurityScopedResource()
        
        var image: UIImage?
        
        if isFileType(format: .image, atURL: url) {
            image = UIImage(contentsOfFile: url.path)
        }
        
        if isFileType(format: .movie, atURL: url) {
            image = getThumbnailImage(forUrl: url)
        }
        
        guard let image = image else {
            return (image: nil, url: nil, resolution: nil)
        }
        
        let resizedImage = resizeImage(
            image: image,
            targetSize: FilesConstants.previewSize
        )
        let imageURL = try? getUrl(
            for: resizedImage,
            name: FilesConstants.previewTag + url.lastPathComponent
        )
        
        return (image: resizedImage, url: imageURL, resolution: image.size)
    }
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            
            let image = UIImage(cgImage: thumbnailImage)
            return image
        } catch {
            return nil
        }
    }
}

private let cachePath = "downloads/cache"
