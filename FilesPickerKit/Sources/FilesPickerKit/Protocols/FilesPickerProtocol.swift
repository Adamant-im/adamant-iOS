//
//  FilesPickerProtocol.swift
//
//
//  Created by Stanislav Jelezoglo on 20.05.2024.
//

import UIKit
import CommonKit
import QuickLook

public protocol FilesPickerProtocol {
    var previewExtension: String {
        get
    }
    
    func getFileSize(from url: URL) throws -> Int64
    func getUrl(for image: UIImage?, name: String) throws -> URL
    func validateFiles(_ files: [FileResult]) throws
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage
    func getOriginalSize(for url: URL) -> CGSize?
    func getThumbnailImage(
        forUrl url: URL,
        originalSize: CGSize?
    ) async throws -> UIImage?
    func getFileResult(for url: URL) throws -> FileResult
    
    @MainActor
    func getUrlConforms(
        to type: UTType,
        for itemProvider: NSItemProvider
    ) async throws -> URL
    
    @MainActor
    func getUrl(for itemProvider: NSItemProvider) async throws -> URL
    
    @MainActor
    func getFileURL(
        by type: String,
        itemProvider: NSItemProvider
    ) async throws -> URL
    
    func getFileResult(for image: UIImage) throws -> FileResult
    func getVideoDuration(from url: URL) -> Float64?
    func getMimeType(for url: URL) -> String? 
}
