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

final class DocumentPickerService: NSObject, FilePickerProtocol {
    let documentPicker = UIDocumentPickerViewController(
        forOpeningContentTypes: [.data, .content],
        asCopy: false
    )

    private var onPreparedDataCallback: (([FileResult]) -> Void)?

    func startPicker(completion: (([FileResult]) -> Void)?) {
        onPreparedDataCallback = completion
        
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = self
        UIApplication.shared.topViewController()?.present(documentPicker, animated: true)
    }
}

extension DocumentPickerService: UIDocumentPickerDelegate {
    func documentPicker(
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
        
        onPreparedDataCallback?(files)
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
        
        let resizedImage = resizeImage(image: image, targetSize: .init(squareSize: 50))
        let imageURL = try? getUrl(for: resizedImage, name: url.lastPathComponent)
        
        return (image: resizedImage, url: imageURL)
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
        ).appendingPathComponent("cachePath")

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let fileURL = folder.appendingPathComponent(name)

        try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        return fileURL
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
