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

public final class MediaPickerService: NSObject, FilePickerProtocol {
    private var helper = FilesPickerKitHelper()
    
    public var onPreparedDataCallback: ((Result<[FileResult], Error>) -> Void)?
    public var onPreparingDataCallback: (() -> Void)?
    
    public override init() { }
}

extension MediaPickerService: PHPickerViewControllerDelegate {
    public func picker(
        _ picker: PHPickerViewController,
        didFinishPicking results: [PHPickerResult]
    ) {
        picker.dismiss(animated: true, completion: .none)
        onPreparingDataCallback?()
        
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
                
                let resizedPreview = helper.resizeImage(
                    image: preview,
                    targetSize: FilesConstants.previewSize
                )
                
                let previewUrl = try? helper.getUrl(for: resizedPreview, name: url.lastPathComponent)
                
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
                let previewUrl = try? helper.getUrl(for: preview, name: url.lastPathComponent)
                
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
        
        do {
            try helper.validateFiles(dataArray)
            onPreparedDataCallback?(.success(dataArray))
        } catch {
            onPreparedDataCallback?(.failure(error))
        }
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
            let resizedImage = helper.resizeImage(
                image: image,
                targetSize: FilesConstants.previewSize
            )
            return resizedImage
        } catch {
            return nil
        }
    }
}
