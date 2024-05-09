//
//  FilesStorageProprietiesProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 03.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

protocol FilesStorageProprietiesProtocol {
    func autoDownloadPreviewPolicy() -> DownloadPolicy
    func setAutoDownloadPreview(_ value: DownloadPolicy)
    func autoDownloadFullMediaPolicy() -> DownloadPolicy
    func setAutoDownloadFullMedia(_ value: DownloadPolicy)
    func saveFileEncrypted() -> Bool
    func setSaveFileEncrypted(_ value: Bool)
}
