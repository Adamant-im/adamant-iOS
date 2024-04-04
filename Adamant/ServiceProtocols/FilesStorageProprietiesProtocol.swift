//
//  FilesStorageProprietiesProtocol.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 03.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

protocol FilesStorageProprietiesProtocol {
    func enabledAutoDownloadPreview() -> Bool
    func setEnabledAutoDownloadPreview(_ value: Bool)
}
