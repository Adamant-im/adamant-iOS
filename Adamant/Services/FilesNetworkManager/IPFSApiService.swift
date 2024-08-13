//
//  IPFSApiService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum IPFSApiCommands {
    static let file = (
        upload: "api/file/upload",
        download: "api/file/",
        fieldName: "files"
    )
}

final class IPFSApiService: FileApiServiceProtocol {
    let service: BlockchainHealthCheckWrapper<IPFSApiCore>
    
    init(
        healthCheckWrapper: BlockchainHealthCheckWrapper<IPFSApiCore>
    ) {
        service = healthCheckWrapper
    }
    
    func request<Output>(
        _ request: @Sendable (APICoreProtocol, Node) async -> ApiServiceResult<Output>
    ) async -> ApiServiceResult<Output> {
        await service.request { admApiCore, node in
            await request(admApiCore.apiCore, node)
        }
    }
    
    func uploadFile(
        data: Data,
        uploadProgress: @escaping ((Progress) -> Void)
    ) async throws -> String {
        let model: MultipartFormDataModel = .init(
            keyName: IPFSApiCommands.file.fieldName,
            fileName: defaultFileName,
            data: data
        )
        
        let result: IpfsDTO = try await request { core, node in
            await core.sendRequestMultipartFormDataJsonResponse(
                node: node,
                path: IPFSApiCommands.file.upload,
                models: [model],
                uploadProgress: uploadProgress
            )
        }.get()
        
        guard let cid = result.cids.first else {
            throw FileManagerError.cantUploadFile
        }
        
        return cid
    }
    
    func downloadFile(
        id: String,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async throws -> Data {
        let result: Data = try await request { core, node in
            let result: APIResponseModel = await core.sendRequest(
                node: node,
                path: "\(IPFSApiCommands.file.download)\(id)",
                downloadProgress: downloadProgress
            )
            
            if let error = handleError(result) {
                return .failure(error)
            }
            
            return result.result
        }.get()
        
        return result
    }
}

private extension IPFSApiService {
    func handleError(_ result: APIResponseModel) -> ApiServiceError? {
        guard let code = result.code,
              !(200 ... 299).contains(code)
        else { return nil }
        
        let serverError = ApiServiceError.serverError(error: "\(code)")
        let error = code == 500 || code == 502 || code == 504
        ? .networkError(error: serverError)
        : serverError
        
        return error
    }
}

private let defaultFileName = "fileName"
