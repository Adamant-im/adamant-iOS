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

@MainActor
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
        picker.dismiss(animated: true, completion: { [weak self] in
            self?.onPreparingDataCallback?()
            
            Task {
                await self?.processResults(results)
            }
        })
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
                guard let url = try? await helper.getUrl(for: itemProvider),
                      let preview = try? await getPhoto(from: itemProvider),
                      let fileSize = try? helper.getFileSize(from: url)
                else { continue }
                
                let resizedPreview = helper.resizeImage(
                    image: preview,
                    targetSize: FilesConstants.previewSize
                )
                
                let previewUrl = try? helper.getUrl(
                    for: resizedPreview,
                    name: FilesConstants.previewTag + url.lastPathComponent
                )
                
                dataArray.append(
                    .init(
                        url: url,
                        type: .image,
                        preview: resizedPreview,
                        previewUrl: previewUrl,
                        size: fileSize,
                        name: itemProvider.suggestedName, 
                        extenstion: url.pathExtension, 
                        resolution: preview.size
                    )
                )
            }
            
            if utType.conforms(to: .movie) {
                guard let url = try? await helper.getUrl(for: itemProvider),
                      let fileSize = try? helper.getFileSize(from: url)
                else { continue }
                
                let originalSize = helper.getOriginalSize(for: url)
                
                let thumbnailImage = try? await helper.getThumbnailImage(
                    forUrl: url, 
                    originalSize: originalSize
                )
                
                let previewUrl = try? helper.getUrl(
                    for: thumbnailImage,
                    name: FilesConstants.previewTag + url.lastPathComponent
                )
                
                dataArray.append(
                    .init(
                        url: url,
                        type: .video,
                        preview: thumbnailImage,
                        previewUrl: previewUrl,
                        size: fileSize,
                        name: itemProvider.suggestedName,
                        extenstion: url.pathExtension,
                        resolution: originalSize
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
}
