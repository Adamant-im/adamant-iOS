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
    public var preSelectedFiles: [FileResult] = []
    
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
        do {
            var dataArray: [FileResult] = []
            
            for result in results {
                let itemProvider = result.itemProvider
                if isConforms(to: .image, itemProvider.registeredTypeIdentifiers) {
                    let url = try await helper.getUrlConforms(
                        to: .image,
                        for: itemProvider
                    )
                    
                    let preview = try getPhoto(
                        from: url,
                        name: itemProvider.suggestedName ?? .empty
                    )
                    
                    let fileSize = try helper.getFileSize(from: url)
                    
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
                            assetId: result.assetIdentifier,
                            url: url,
                            type: .image,
                            preview: resizedPreview,
                            previewUrl: previewUrl, 
                            previewExtension: helper.previewExtension,
                            size: fileSize,
                            name: itemProvider.suggestedName,
                            extenstion: url.pathExtension,
                            resolution: preview.size
                        )
                    )
                } else if isConforms(to: .movie, itemProvider.registeredTypeIdentifiers) {
                    let url = try await helper.getUrlConforms(
                        to: .movie,
                        for: itemProvider
                    )
                    
                    let fileSize = try helper.getFileSize(from: url)
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
                            assetId: result.assetIdentifier,
                            url: url,
                            type: .video,
                            preview: thumbnailImage,
                            previewUrl: previewUrl,
                            previewExtension: helper.previewExtension,
                            size: fileSize,
                            name: itemProvider.suggestedName,
                            extenstion: url.pathExtension,
                            resolution: originalSize
                        )
                    )
                } else {
                    if let file = preSelectedFiles.first(where: {
                        $0.assetId == result.assetIdentifier
                    }) {
                        dataArray.append(file)
                    } else {
                        throw FilePickersError.cantSelectFile(itemProvider.suggestedName ?? .empty)
                    }
                }
            }
            
            try helper.validateFiles(dataArray)
            onPreparedDataCallback?(.success(dataArray))
        } catch {
            onPreparedDataCallback?(.failure(error))
        }
        
        preSelectedFiles.removeAll()
    }
    
    func getPhoto(from url: URL, name: String) throws -> UIImage {
        guard let image = UIImage(contentsOfFile: url.path) else {
            throw FilePickersError.cantSelectFile(name)
        }
        
        return image
    }
    
    func isConforms(to type: UTType, _ registeredTypeIdentifiers: [String]) -> Bool {
        for identifier in registeredTypeIdentifiers {
            guard !identifier.contains("private") else {
                continue
            }
            
            if let uiType = UTType(identifier), uiType.conforms(to: type) {
                return true
            }
        }
        
        return false
    }
}
