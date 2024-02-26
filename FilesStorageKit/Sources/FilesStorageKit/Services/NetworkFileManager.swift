//
//  NetworkFileManager.swift
//
//
//  Created by Stanislav Jelezoglo on 26.02.2024.
//

import Foundation

final class NetworkFileManager: NetworkFileManagerProtocol {
    private let baseApi: ApiManagerProtocol = BaseApiManager()
    
    func uploadFiles(_ data: Data, type: NetworkFileProtocolType) async throws -> String {
        switch type {
        case .base:
            return try await baseApi.uploadFile(data: data)
        }
    }
    
    func downloadFile(_ id: String, type: String) async throws -> Data {
        guard let netwrokProtocol = NetworkFileProtocolType(rawValue: type) else {
            throw FileManagerError.cantDownloadFile
        }
        
        switch netwrokProtocol {
        case .base:
            return try await baseApi.downloadFile(id: id)
        }
    }
}
