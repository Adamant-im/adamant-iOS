//
//  NetworkFileManager.swift
//
//
//  Created by Stanislav Jelezoglo on 26.02.2024.
//

import Foundation

final class NetworkFileManager: NetworkFileManagerProtocol {
    private let uploadCareApi: ApiManagerProtocol = UploadCareApiManager()
    
    func uploadFiles(_ data: Data, type: NetworkFileProtocolType) async throws -> String {
        switch type {
        case .uploadCareApi:
            return try await uploadCareApi.uploadFile(data: data)
        }
    }
    
    func downloadFile(_ id: String, type: String) async throws -> Data {
        guard let netwrokProtocol = NetworkFileProtocolType(rawValue: type) else {
            throw FileManagerError.cantDownloadFile
        }
        
        switch netwrokProtocol {
        case .uploadCareApi:
            return try await uploadCareApi.downloadFile(id: id)
        }
    }
}
