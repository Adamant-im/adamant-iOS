//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 11.02.2024.
//

import CommonKit
import UIKit
import Photos
import PhotosUI

final class MediaPickerService: NSObject, FilePickerProtocol {
    private var onPreparedDataCallback: (([FileResult]) -> Void)?

    func startPicker(completion: (([FileResult]) -> Void)?) {
        onPreparedDataCallback = completion
        
        var phPickerConfig = PHPickerConfiguration(photoLibrary: .shared())
        phPickerConfig.selectionLimit = FilesConstants.maxFilesCount
        phPickerConfig.filter = PHPickerFilter.any(of: [.images, .videos])
        
        let phPickerVC = PHPickerViewController(configuration: phPickerConfig)
        phPickerVC.delegate = self
        UIApplication.shared.topViewController()?.present(phPickerVC, animated: true)
    }
}

extension MediaPickerService: PHPickerViewControllerDelegate {
    func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true, completion: .none)
        Task {
            await processResults(results)
        }
    }
}

private extension MediaPickerService {
    func processResults(_ results: [PHPickerResult]) async {
        var dataArray: [FileResult] = []
        
        for result in results {
            let itemProvider = result.itemProvider
            
            guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first,
                  let utType = UTType(typeIdentifier)
            else { continue }
         
            if utType.conforms(to: .image) {
                guard let url = try? await getUrl(from: itemProvider, typeIdentifier: typeIdentifier),
                      let preview = try? await getPhoto(from: itemProvider),
                      let fileSize = try? getFileSize(from: url)
                else { continue }
                
                let resizedPreview = self.resizeImage(image: preview, targetSize: .init(squareSize: 50))
                
                let previewUrl = try? getUrl(for: resizedPreview, name: url.lastPathComponent)
                
                dataArray.append(
                    .init(
                        url: url,
                        type: .image,
                        preview: resizedPreview,
                        previewUrl: previewUrl,
                        size: fileSize,
                        name: itemProvider.suggestedName, 
                        extenstion: "JPG"
                    )
                )
            }
            
            if utType.conforms(to: .movie) {
                guard let url = try? await getUrl(from: itemProvider, typeIdentifier: typeIdentifier),
                      let fileSize = try? getFileSize(from: url)
                else { continue }
                
                let preview = getThumbnailImage(forUrl: url)
                let previewUrl = try? getUrl(for: preview, name: url.lastPathComponent)
                
                dataArray.append(
                    .init(
                        url: url,
                        type: .video,
                        preview: preview,
                        previewUrl: previewUrl,
                        size: fileSize,
                        name: itemProvider.suggestedName,
                        extenstion: url.pathExtension
                    )
                )
            }
        }
        
        onPreparedDataCallback?(dataArray)
    }
    
    func getFileSize(from fileURL: URL) throws -> Int64 {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        
        guard let fileSize = fileAttributes[.size] as? Int64 else {
            throw FileValidationError.fileNotFound
        }
        
        return fileSize
    }
    
    func getPhoto(from itemProvider: NSItemProvider) async throws -> UIImage {
        let objectType: NSItemProviderReading.Type = UIImage.self
        
        guard itemProvider.canLoadObject(ofClass: objectType) else {
            throw FileValidationError.tooManyFiles
        }
        
        return try await withUnsafeThrowingContinuation { continuation in
            itemProvider.loadObject(ofClass: objectType) { object, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let image = object as? UIImage else {
                    continuation.resume(throwing: FileValidationError.tooManyFiles)
                    return
                }
                
                continuation.resume(returning: image)
            }
        }
    }
    
    func getUrl(
        from itemProvider: NSItemProvider,
        typeIdentifier: String
    ) async throws -> URL {
        try await withUnsafeThrowingContinuation { continuation in
            itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let url = url else {
                    continuation.resume(throwing: FileValidationError.tooManyFiles)
                    return
                }
                
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                guard let targetURL = documentsDirectory?.appendingPathComponent(url.lastPathComponent) else { return }
                
                do {
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
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            
            let image = UIImage(cgImage: thumbnailImage)
            let resizedImage = resizeImage(image: image, targetSize: .init(squareSize: 50))
            return resizedImage
        } catch {
            return nil
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
