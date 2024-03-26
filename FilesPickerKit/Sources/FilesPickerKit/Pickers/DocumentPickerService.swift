//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//

import Foundation
import UIKit
import CommonKit
import MobileCoreServices
import AVFoundation

public final class DocumentPickerService: NSObject, FilePickerProtocol {
    private var helper = FilesPickerKitHelper()

    public var onPreparedDataCallback: ((Result<[FileResult], Error>) -> Void)?
    public var onPreparingDataCallback: (() -> Void)?
    
    public override init() { }
}

extension DocumentPickerService: UIDocumentPickerDelegate {
    public func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        let files = urls.compactMap {
            let preview = getPreview(for: $0)
            
            return FileResult.init(
                url: $0,
                type: .other,
                preview: preview.image,
                previewUrl: preview.url,
                size: (try? getFileSize(from: $0)) ?? .zero,
                name: $0.lastPathComponent,
                extenstion: $0.pathExtension, 
                resolution: preview.resolution
            )
        }
        
        do {
            try helper.validateFiles(files)
            onPreparedDataCallback?(.success(files))
        } catch {
            onPreparedDataCallback?(.failure(error))
        }
    }
}

private extension DocumentPickerService {
    func getFileSize(from fileURL: URL) throws -> Int64 {
        _ = fileURL.startAccessingSecurityScopedResource()
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        
        guard let fileSize = fileAttributes[.size] as? Int64 else {
            throw FileValidationError.fileNotFound
        }
        
        fileURL.stopAccessingSecurityScopedResource()
        return fileSize
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
            image = helper.getThumbnailImage(forUrl: url)
        }
        
        guard let image = image else {
            return (image: nil, url: nil, resolution: nil)
        }
        
        let resizedImage = helper.resizeImage(
            image: image,
            targetSize: FilesConstants.previewSize
        )
        let imageURL = try? helper.getUrl(for: resizedImage, name: url.lastPathComponent)
        
        return (image: resizedImage, url: imageURL, resolution: image.size)
    }
}
