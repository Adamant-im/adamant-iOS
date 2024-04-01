//
//  FilesStorageProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit
import FilesStorageKit

protocol FilesStorageProtocol {
    func getPreview(for id: String, type: String) -> UIImage?
    
    func isCached(_ id: String) -> Bool
    
    func getFileURL(with id: String) throws -> URL
    
    func uploadFile(
        _ file: FileResult,
        recipientPublicKey: String,
        senderPrivateKey: String
    ) async throws -> (id: String, nonce: String, idPreview: String?, noncePreview: String?)
    
    func downloadFile(
        id: String,
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String,
        previewId: String?,
        previewNonce: String?
    ) async throws
    
    func getCacheSize() throws -> Int64
    
    func clearCache() throws
    
    func cachePreview(
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        previewId: String,
        previewNonce: String
    ) async throws
}

extension FilesStorageKit: FilesStorageProtocol { }
