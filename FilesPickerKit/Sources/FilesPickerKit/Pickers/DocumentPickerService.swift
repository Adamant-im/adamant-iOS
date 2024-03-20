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
                extenstion: $0.pathExtension
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
    
    func isImage(atURL fileURL: URL) -> Bool {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileURL.pathExtension as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        
        return UTTypeConformsTo(uti, kUTTypeImage)
    }
    
    func getPreview(for url: URL) -> (image: UIImage?, url: URL?) {
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        _ = url.startAccessingSecurityScopedResource()
        
        guard isImage(atURL: url),
              let image = UIImage(contentsOfFile: url.path)
        else {
            return (image: nil, url: nil)
        }
        
        let resizedImage = helper.resizeImage(image: image, targetSize: .init(squareSize: 50))
        let imageURL = try? helper.getUrl(for: resizedImage, name: url.lastPathComponent)
        
        return (image: resizedImage, url: imageURL)
    }
}
