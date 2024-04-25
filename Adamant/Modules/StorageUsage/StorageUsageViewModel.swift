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

enum DownloadPolicy: String {
    case everybody
    case nobody
    case contacts
    
    var title: String {
        switch self {
        case .everybody:
            return .localized("Storage.DownloadPolicy.Everybody.Title")
        case .nobody:
            return .localized("Storage.DownloadPolicy.Nobody.Title")
        case .contacts:
            return .localized("Storage.DownloadPolicy.Contacts.Title")
        }
    }
}

@MainActor
final class StorageUsageViewModel: ObservableObject {
    private let filesStorage: FilesStorageProtocol
    private let dialogService: DialogService
    private let filesStorageProprieties: FilesStorageProprietiesProtocol
    
    @Published var storageUsedDescription: String?
    @Published var autoDownloadPreview: DownloadPolicy = .everybody
    @Published var autoDownloadFullMedia: DownloadPolicy = .everybody
    
    enum AutoDownloadMediaType {
        case preview
        case fullMedia
        
        var title: String {
            switch self {
            case .preview:
                return .localized("Storage.AutoDownloadPreview.Title")
            case .fullMedia:
                return .localized("Storage.AutoDownloadFullMedia.Title")
            }
        }
    }
    
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
        autoDownloadPreview = filesStorageProprieties.autoDownloadPreviewPolicy()
        autoDownloadFullMedia = filesStorageProprieties.autoDownloadFullMediaPolicy()
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
    
    func presentPicker(for type: AutoDownloadMediaType) {
        let action: ((DownloadPolicy) -> Void)? = { [weak self] policy in
            guard let self = self else { return }
            
            switch type {
            case .preview:
                self.filesStorageProprieties.setAutoDownloadPreview(policy)
                self.autoDownloadPreview = policy
            case .fullMedia:
                self.filesStorageProprieties.setAutoDownloadFullMedia(policy)
                self.autoDownloadFullMedia = policy
            }
            NotificationCenter.default.post(name: .Storage.storageProprietiesUpdated, object: nil)
        }
        
        dialogService.showAlert(
            title: nil,
            message: nil,
            style: .actionSheet,
            actions: [
                makeAction(
                    title: DownloadPolicy.everybody.title,
                    action: { [action] _ in action?(.everybody) }
                ),
                makeAction(
                    title: DownloadPolicy.contacts.title,
                    action: { [action] _ in action?(.contacts) }
                ),
                makeAction(
                    title: DownloadPolicy.nobody.title,
                    action: { [action] _ in action?(.nobody) }
                ),
                makeCancelAction()
            ],
            from: nil
        )
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

private extension StorageUsageViewModel {
    func makeAction(title: String, action: ((UIAlertAction) -> Void)?) -> UIAlertAction {
        .init(
            title: title,
            style: .default,
            handler: action
        )
    }
    
    func makeCancelAction() -> UIAlertAction {
        .init(title: .adamant.alert.cancel, style: .cancel, handler: nil)
    }
}
