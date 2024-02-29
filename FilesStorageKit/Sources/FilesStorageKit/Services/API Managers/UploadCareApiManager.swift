//
//  BaseApiManager.swift
//
//
//  Created by Stanislav Jelezoglo on 20.02.2024.
//

import Foundation
import Uploadcare

final class UploadCareApiManager: ApiManagerProtocol {
    private var uploadcare: Uploadcare
    
    init() {
        self.uploadcare = Uploadcare(withPublicKey: "a309ad74a3c543fed143")
    }
    
    func uploadFile(data: Data) async throws -> String {
        let fileForUploading = uploadcare.file(fromData: data)
        try await fileForUploading.upload(withName: String.random(length: 6), store: .auto)
        return fileForUploading.fileId
    }
    
    func downloadFile(id: String) async throws -> Data {
        let request = URLRequest(url: URL(string: "https://ucarecdn.com/\(id)/")!)
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
