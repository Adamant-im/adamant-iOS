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
        type: NetworkFileProtocolType
    ) async throws -> String {
        switch type {
        case .ipfs:
            return try await ipfsService.uploadFile(data: data)
        }
    }
    
    func downloadFile(_ id: String, type: String) async throws -> Data {
        guard let netwrokProtocol = NetworkFileProtocolType(rawValue: type) else {
            throw FileManagerError.cantDownloadFile
        }
        
        switch netwrokProtocol {
        case .ipfs:
            return try await ipfsService.downloadFile(id: id)
        }
    }
}
