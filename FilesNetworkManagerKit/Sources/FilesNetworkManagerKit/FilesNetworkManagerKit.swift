// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public final class FilesNetworkManager {
    private let uploadCareApi: ApiManagerProtocol = UploadCareApiManager()
    
    public init() { }
    
    public func uploadFiles(_ data: Data, type: NetworkFileProtocolType) async throws -> String {
        switch type {
        case .uploadCareApi:
            return try await uploadCareApi.uploadFile(data: data)
        }
    }
    
    public func downloadFile(_ id: String, type: String) async throws -> Data {
        guard let netwrokProtocol = NetworkFileProtocolType(rawValue: type) else {
            throw FileManagerError.cantDownloadFile
        }
        
        switch netwrokProtocol {
        case .uploadCareApi:
            return try await uploadCareApi.downloadFile(id: id)
        }
    }
}
