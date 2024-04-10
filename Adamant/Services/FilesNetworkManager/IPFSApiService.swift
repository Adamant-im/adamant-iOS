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
        upload: "file/upload",
        download: "file/",
        field: "files"
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
    
    func uploadFile(data: Data) async throws -> String {
        let result: IpfsDTO = try await request { core, node in
            await core.sendRequestMultipartFormDataJsonResponse(
                node: node,
                path: IPFSApiCommands.file.upload,
                data: [IPFSApiCommands.file.field: data])
        }.get()
        
        guard let cid = result.cids.first else {
            throw FileManagerError.cantUploadFile
        }
        
        return cid
    }
    
    func downloadFile(id: String) async throws -> Data {
        let result: Data = try await request { core, node in
            await core.sendRequest(
                node: node,
                path: "\(IPFSApiCommands.file.download)\(id)"
            )
        }.get()
        
        return result
    }
}
