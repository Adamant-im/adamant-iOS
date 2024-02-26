//
//  BaseApiManager.swift
//
//
//  Created by Stanislav Jelezoglo on 20.02.2024.
//

import Foundation

final class BaseApiManager: ApiManagerProtocol {
    //private var uploadcare: Uploadcare
    
//    init() {
//        self.uploadcare = Uploadcare(withPublicKey: "a309ad74a3c543fed143")
//    }
    
    func uploadFile(data: Data) async throws -> String {
        ""
//        var fileForUploading = uploadcare.file(fromData: data)
//        try await fileForUploading.upload(withName: "test", store: .auto)
//        return fileForUploading.fileId
    }
    
    func downloadFile(id: String) async throws -> Data {
        Data()
    }
}
