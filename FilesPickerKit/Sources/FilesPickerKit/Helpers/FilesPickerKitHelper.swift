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
        guard let data = image?.jpegData(compressionQuality: 1.0) else {
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let newSize = getPreviewSize(from: image.size)
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
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
        let preview = getPreview(for: url)
        let fileSize = try getFileSize(from: url)
        return FileResult(
            url: url,
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
    func getUrl(for itemProvider: NSItemProvider) async throws -> URL {
        guard let type = itemProvider.registeredTypeIdentifiers.first
        else {
            throw FileValidationError.fileNotFound
        }
        
        return try await withUnsafeThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let url = url else {
                    continuation.resume(throwing: FileValidationError.tooManyFiles)
                    return
                }
                
                do {
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
                    
                    let targetURL = folder.appendingPathComponent(url.lastPathComponent)
                    
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    
                    try FileManager.default.copyItem(at: url, to: targetURL)
                    
                    continuation.resume(returning: targetURL)
                } catch {
                    continuation.resume(throwing: error)
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
