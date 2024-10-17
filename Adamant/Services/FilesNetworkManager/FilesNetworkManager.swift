//
//  FilesNetworkManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

final class FilesNetworkManager: FilesNetworkManagerProtocol {
    private let ipfsService: IPFSApiService
    
    init(ipfsService: IPFSApiService) {
        self.ipfsService = ipfsService
    }
    
    func uploadFiles(
        _ data: Data,
        type: NetworkFileProtocolType,
        uploadProgress: @escaping @Sendable (Progress) -> Void
    ) async -> FileApiServiceResult<String> {
        switch type {
        case .ipfs:
            return await ipfsService.uploadFile(data: data, uploadProgress: uploadProgress)
        }
    }
    
    func downloadFile(
        _ id: String,
        type: String,
        downloadProgress: @escaping @Sendable (Progress) -> Void
    ) async -> FileApiServiceResult<Data> {
        guard let netwrokProtocol = NetworkFileProtocolType(rawValue: type) else {
            return .failure(.cantDownloadFile)
        }
        
        switch netwrokProtocol {
        case .ipfs:
            return await ipfsService.downloadFile(
                id: id,
                downloadProgress: downloadProgress
            )
        }
    }
}
