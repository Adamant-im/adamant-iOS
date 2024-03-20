// The Swift Programming Language
// https://docs.swift.org/swift-book

import CommonKit
import UIKit
import SwiftUI

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
