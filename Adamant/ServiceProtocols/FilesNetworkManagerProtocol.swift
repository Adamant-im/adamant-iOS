//
//  FilesNetworkManagerProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

protocol FilesNetworkManagerProtocol {
    func uploadFiles(
        _ data: Data,
        type: NetworkFileProtocolType,
        uploadProgress: @escaping ((Progress) -> Void)
    ) async -> FileApiServiceResult<String>
    
    func downloadFile(
        _ id: String,
        type: String,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> FileApiServiceResult<Data>
}
