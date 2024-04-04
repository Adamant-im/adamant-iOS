//
//  StorageUsageViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.03.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import SwiftUI

public extension Notification.Name {
    struct Storage {
        public static let storageClear = Notification.Name("adamant.storage.clear")
        public static let storageProprietiesUpdated = Notification.Name("adamant.storage.ProprietiesUpdated")
    }
}

@MainActor
final class StorageUsageViewModel: ObservableObject {
    private let filesStorage: FilesStorageProtocol
    private let dialogService: DialogService
    private let filesStorageProprieties: FilesStorageProprietiesProtocol
    
    @Published var storageUsedDescription: String?
    @Published var autoDownloadPreview: Bool = true
    
    nonisolated init(
        filesStorage: FilesStorageProtocol,
        dialogService: DialogService,
        filesStorageProprieties: FilesStorageProprietiesProtocol
    ) {
        self.filesStorage = filesStorage
        self.dialogService = dialogService
        self.filesStorageProprieties = filesStorageProprieties
        
    }
    
    func loadData() {
        autoDownloadPreview = filesStorageProprieties.enabledAutoDownloadPreview()
        updateCacheSize()
    }
    
    func clearStorage() {
        do {
            dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
            try filesStorage.clearCache()
            dialogService.dismissProgress()
            dialogService.showSuccess(withMessage: nil)
            updateCacheSize()
            NotificationCenter.default.post(name: .Storage.storageClear, object: nil)
        } catch {
            dialogService.dismissProgress()
            dialogService.showError(
                withMessage: error.localizedDescription,
                supportEmail: false,
                error: error
            )
        }
    }
    
    func togglePreviewContent() {
        filesStorageProprieties.setEnabledAutoDownloadPreview(autoDownloadPreview)
        NotificationCenter.default.post(name: .Storage.storageProprietiesUpdated, object: nil)
    }
}

private extension StorageUsageViewModel {
    func updateCacheSize() {
        DispatchQueue.global().async {
            let size = (try? self.filesStorage.getCacheSize()) ?? .zero
            DispatchQueue.main.async {
                self.storageUsedDescription = self.formatSize(size)
            }
        }
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file

        return formatter.string(fromByteCount: bytes)
    }
}
