//
//  FileApiServiceProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol FileApiServiceProtocol: WalletApiService {
    func uploadFile(
        data: Data,
        uploadProgress: @escaping ((Progress) -> Void)
    ) async -> FileApiServiceResult<String>
    
    func downloadFile(
        id: String,
        downloadProgress: @escaping ((Progress) -> Void)
    ) async -> FileApiServiceResult<Data>
}
