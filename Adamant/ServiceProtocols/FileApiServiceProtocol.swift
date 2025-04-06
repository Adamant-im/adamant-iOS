//
//  FileApiServiceProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol FileApiServiceProtocol: ApiServiceProtocol {
    func uploadFile(
        data: Data,
        uploadProgress: @escaping @Sendable (Progress) -> Void
    ) async -> FileApiServiceResult<String>

    func downloadFile(
        id: String,
        downloadProgress: @escaping @Sendable (Progress) -> Void
    ) async -> FileApiServiceResult<Data>
}
