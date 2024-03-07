//
//  FilesStorageProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import UIKit
import CommonKit
import FilesStorageKit

protocol FilesStorageProtocol {
    func getPreview(for id: String, type: String) -> UIImage
    
    func isCached(_ id: String) -> Bool
    
    func uploadFile(
        _ file: FileResult,
        recipientPublicKey: String,
        senderPrivateKey: String
    ) async throws -> (id: String, nonce: String)
    
    func downloadFile(
        id: String,
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String
    ) async throws
}

extension FilesStorageKit: FilesStorageProtocol { }
