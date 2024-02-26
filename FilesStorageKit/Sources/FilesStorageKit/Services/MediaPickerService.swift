//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 11.02.2024.
//

import Foundation
import UIKit
import Photos
import PhotosUI

final class MediaPickerService: NSObject, FilePickerProtocol {
    private var onPreparedDataCallback: (([FileResult]) -> Void)?

    func startPicker(
        window: UIWindow,
        completion: (([FileResult]) -> Void)?
    ) {
        onPreparedDataCallback = completion
        
        var phPickerConfig = PHPickerConfiguration(photoLibrary: .shared())
        phPickerConfig.selectionLimit = Constants.maxFilesCount
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
                
                dataArray.append(
                    .init(
                        url: url,
                        type: .image,
                        preview: preview,
                        size: fileSize,
                        name: itemProvider.suggestedName
                    )
                )
            }
            
            if utType.conforms(to: .movie) {
                guard let url = try? await getUrl(from: itemProvider, typeIdentifier: typeIdentifier),
                      let fileSize = try? getFileSize(from: url)
                else { continue }
                
                let preview = getThumbnailImage(forUrl: url)
                
                dataArray.append(.init(
                    url: url,
                    type: .video,
                    preview: preview,
                    size: fileSize,
                    name: itemProvider.suggestedName)
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
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print("error in thumbail=", error)
            return nil
        }
    }
}

//private extension MediaPickerService {
//    func fetchData(for assets: [PHAsset]) {
//        var dataArray: [FileResult] = []
//        let dispatchGroup = DispatchGroup()
//        
//        for asset in assets {
//            dispatchGroup.enter()
//            
//            if asset.mediaType == .image {
//                requestImage(asset: asset) { data in
//                    defer { dispatchGroup.leave() }
//                    
//                    guard let data = data else { return }
//                    dataArray.append(.init(
//                        data: data,
//                        type: .image,
//                        preview: UIImage(data: data))
//                    )
//                }
//            }
//            
//            if asset.mediaType == .video {
//                requestVideo(asset: asset) { data, imgData in
//                    defer { dispatchGroup.leave() }
//                    
//                    guard let data = data, let imgData = imgData else { return }
//                    dataArray.append(
//                        .init(
//                            data: data,
//                            type: .video,
//                            preview: UIImage(data: imgData))
//                    )
//                }
//            }
//        }
//        
//        dispatchGroup.notify(queue: DispatchQueue.main) {
//            self.onPreparedDataCallback?(dataArray)
//        }
//    }
//    
//    func requestImage(
//        asset: PHAsset,
//        completion: ((Data?) -> Void)?,
//        tryNumber: Int = 1
//    ) {
//        requestImageData(asset: asset) { [weak self, asset] image in
//            if image == nil && tryNumber < 4 {
//                self?.requestImage(
//                    asset: asset,
//                    completion: completion,
//                    tryNumber: tryNumber + 1
//                )
//                return
//            }
//            
//            completion?(image)
//        }
//    }
//    
//    func requestImageData(
//        asset: PHAsset,
//        completion: ((Data?) -> Void)?
//    ) {
//        let imgManager = PHImageManager.default()
//        
//        let options = PHImageRequestOptions()
//        options.isSynchronous = false
//        options.deliveryMode = .opportunistic
//        options.isNetworkAccessAllowed = true
//        options.resizeMode = .exact
//        
//        imgManager.requestImage(
//            for: asset,
//            targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
//            contentMode: .default,
//            options: options
//        ) { image, info in
//            if info?[PHImageResultIsDegradedKey] as? Bool == true {
//                return
//            }
//            completion?(image?.jpegData(compressionQuality: 0.6))
//        }
//    }
//    
//    func requestVideo(
//        asset: PHAsset,
//        completion: ((Data?, Data?) -> Void)?
//    ) {
//        let options = PHVideoRequestOptions()
//        options.deliveryMode = .fastFormat
//        options.isNetworkAccessAllowed = true
//        
//        PHCachingImageManager().requestAVAsset(
//            forVideo: asset,
//            options: options
//        ) { [weak self] (newAsset, _, _) in
//            guard let newAsset = newAsset as? AVURLAsset
//            else {
//                return
//            }
//            
//            let videoData = try? Data(contentsOf: newAsset.url)
//            
//            self?.requestImage(asset: asset) { data in
//                completion?(videoData, data)
//            }
//        }
//    }
//}

//private extension MediaPickerService {
//    func fetchData(for assets: [PHAsset]) async {
//        var dataArray: [FileResult] = []
//
//        for asset in assets {
//            if asset.mediaType == .image,
//               let imageData = await requestImageData(asset: asset) {
//                let previewImage = UIImage(data: imageData)
//                dataArray.append(.init(
//                    data: imageData,
//                    type: .image,
//                    preview: previewImage)
//                )
//            }
//            
//            if asset.mediaType == .video,
//               let (videoData, imageData) = await requestVideo(asset: asset) {
//                let previewImage = UIImage(data: imageData)
//                dataArray.append(.init(
//                    data: videoData,
//                    type: .video,
//                    preview: previewImage)
//                )
//            }
//        }
//
//        onPreparedDataCallback?(dataArray)
//    }
//    
//    func requestImageData(asset: PHAsset) async -> Data? {
//        let imgManager = PHImageManager.default()
//        
//        let options = PHImageRequestOptions()
//        options.isSynchronous = false
//        options.deliveryMode = .opportunistic
//        options.isNetworkAccessAllowed = true
//        options.resizeMode = .exact
//
//        return await withCheckedContinuation { continuation in
//            imgManager.requestImage(
//                for: asset,
//                targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight),
//                contentMode: .default,
//                options: options
//            ) { image, info in
//                if info?[PHImageResultIsDegradedKey] as? Bool == true {
//                    return
//                }
//                
//                if let imageData = image?.jpegData(compressionQuality: 0.6) {
//                    continuation.resume(returning: imageData)
//                } else {
//                    continuation.resume(returning: nil)
//                }
//            }
//        }
//    }
//    
//    func requestVideo(asset: PHAsset) async -> (Data, Data)? {
//        guard let videoData = await requestVideoData(asset: asset),
//        let imageData = await requestImageData(asset: asset)
//        else {
//            return nil
//        }
//        
//        return (videoData, imageData)
//    }
//    
//    func requestVideoData(asset: PHAsset) async -> Data? {
//        let options = PHVideoRequestOptions()
//        options.deliveryMode = .fastFormat
//        options.isNetworkAccessAllowed = true
//        
//        return await withCheckedContinuation { continuation in
//            PHCachingImageManager().requestAVAsset(
//                forVideo: asset,
//                options: options
//            ) { (newAsset, _, _) in
//                guard let newAsset = newAsset as? AVURLAsset
//                else {
//                    return
//                }
//                
//                let videoData = try? Data(contentsOf: newAsset.url)
//                
//                continuation.resume(returning: videoData)
//            }
//        }
//    }
//}
