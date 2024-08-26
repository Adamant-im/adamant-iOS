// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import SwiftUI
import AVFoundation
import QuickLook
import FilesStorageKit

public final class FilesPickerKit: FilesPickerProtocol {
    private let storageKit: FilesStorageProtocol
    public var previewExtension: String { "jpeg" }
    
    public init(storageKit: FilesStorageProtocol) {
        self.storageKit = storageKit
    }
    
    public func getFileSize(from url: URL) throws -> Int64 {
        try storageKit.getFileSize(from: url).get()
    }
    
    public func getUrl(for image: UIImage?, name: String) throws -> URL {
        try storageKit.getTempUrl(for: image, name: name)
    }
    
    public func validateFiles(_ files: [FileResult]) throws {
        guard files.count <= FilesConstants.maxFilesCount else {
            throw FileValidationError.tooManyFiles
        }
        
        for file in files {
            guard file.size <= FilesConstants.maxFileSize else {
                throw FileValidationError.fileSizeExceedsLimit
            }
        }
    }
    
    public func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let newSize = getPreviewSize(
            from: image.size,
            previewSize: FilesConstants.previewSize
        )
        
        return image.imageResized(to: newSize)
    }
    
    public func getOriginalSize(for url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(
            withMediaType: AVMediaType.video
        ).first
        else { return nil }
        
        let naturalSize = track.naturalSize.applying(track.preferredTransform)
        
        return .init(width: abs(naturalSize.width), height: abs(naturalSize.height))
    }
    
    public func getThumbnailImage(
        forUrl url: URL,
        originalSize: CGSize?
    ) async throws -> UIImage? {
        var thumbnailSize: CGSize?
        
        if let size = originalSize {
            thumbnailSize = getPreviewSize(
                from: size,
                previewSize: FilesConstants.previewVideoSize
            )
        }
        
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: thumbnailSize ?? FilesConstants.previewVideoSize,
            scale: 1.0,
            representationTypes: .thumbnail
        )
        
        let image = try await QLThumbnailGenerator.shared.generateBestRepresentation(
            for: request
        ).uiImage
        
        return image
    }
    
    public func getFileResult(for url: URL) throws -> FileResult {
        try createFileResult(
            from: url,
            name: url.lastPathComponent,
            extension: url.pathExtension
        )
    }

    public func getFileResult(for image: UIImage) throws -> FileResult {
        let fileName = "\(imagePrefix)\(String.random(length: 4)).\(previewExtension)"
        
        let newUrl = try storageKit.getTempUrl(for: image, name: fileName)
        
        return try createFileResult(
            from: newUrl,
            name: fileName,
            extension: previewExtension
        )
    }
    
    @MainActor
    public func getUrlConforms(
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
    public func getUrl(for itemProvider: NSItemProvider) async throws -> URL {
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
    public func getFileURL(
        by type: String,
        itemProvider: NSItemProvider
    ) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: type) { [weak self] url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    if let targetURL = try? self?.storageKit.copyFileToTempCache(from: url) {
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
    
    public func getVideoDuration(from url: URL) -> Float64? {
        guard isFileType(format: .movie, atURL: url) else { return nil }
        
        let asset = AVAsset(url: url)
        
        let duration = asset.duration
        let durationTime = CMTimeGetSeconds(duration)
        
        return durationTime
    }
    
    public func getMimeType(for url: URL) -> String? {
        var mimeType: String?
        
        let pathExtension = url.pathExtension
        if let type = UTType(filenameExtension: pathExtension) {
            mimeType = type.preferredMIMEType
        }
        
        return mimeType
    }
}

private extension FilesPickerKit {
    func createFileResult(
        from url: URL,
        name: String,
        extension: String
    ) throws -> FileResult {
        let newUrl = try storageKit.copyFileToTempCache(from: url)
        let preview = getPreview(for: newUrl)
        let fileSize = try storageKit.getFileSize(from: newUrl).get()
        let duration = getVideoDuration(from: newUrl)
        let mimeType = getMimeType(for: newUrl)
        
        return FileResult(
            assetId: url.absoluteString,
            url: newUrl,
            type: .other,
            preview: preview.image,
            previewUrl: preview.url,
            previewExtension: previewExtension,
            size: fileSize,
            name: name,
            extenstion: `extension`,
            resolution: preview.resolution,
            duration: duration,
            mimeType: mimeType
        )
    }
    
    func getPreviewSize(
        from originalSize: CGSize?,
        previewSize: CGSize
    ) -> CGSize {
        guard let size = originalSize else { return FilesConstants.previewSize }
        
        let width = abs(size.width)
        let height = abs(size.height)
        
        let widthRatio  = previewSize.width  / width
        let heightRatio = previewSize.height / height
        
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
        guard let mimeType = getMimeType(for: fileURL) else { return false }
        
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
        let imageURL = try? storageKit.getTempUrl(
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

private let imagePrefix = "image"
