//
//  FilesStorageProprietiesService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 03.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import Combine
import CommonKit

final class FilesStorageProprietiesService: FilesStorageProprietiesProtocol, @unchecked Sendable {
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    @Atomic private var autoDownloadPreviewState: DownloadPolicy = .everybody
    @Atomic private var autoDownloadFullMediaState: DownloadPolicy = .everybody
    private let autoDownloadPreviewDefaultState: DownloadPolicy = .contacts
    private let autoDownloadFullMediaDefaultState: DownloadPolicy = .contacts
    @Atomic private var saveFileEncryptedValue = true
    private let saveFileEncryptedDefault = true
    
    // MARK: Lifecycle
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
                
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                self?.userLoggedIn()
            }
            .store(in: &notificationsSet)
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedIn() {
        autoDownloadPreviewState = getAutoDownloadPreview()
        autoDownloadFullMediaState = getAutoDownloadFullMedia()
        saveFileEncryptedValue = getSaveFileEncrypted()
    }
    
    private func userLoggedOut() {
        setAutoDownloadPreview(autoDownloadPreviewDefaultState)
        setAutoDownloadFullMedia(autoDownloadFullMediaDefaultState)
        saveFileEncryptedValue = saveFileEncryptedDefault
    }
    
    // MARK: Update data
    
    func saveFileEncrypted() -> Bool {
        saveFileEncryptedValue
    }
    
    func getSaveFileEncrypted() -> Bool {
        guard let result: Bool = securedStore.get(
            StoreKey.storage.saveFileEncrypted
        ) else {
            return saveFileEncryptedDefault
        }
        
        return result
    }
    
    func setSaveFileEncrypted(_ value: Bool) {
        securedStore.set(value, for: StoreKey.storage.saveFileEncrypted)
        saveFileEncryptedValue = value
    }
    
    func autoDownloadPreviewPolicy() -> DownloadPolicy {
        autoDownloadPreviewState
    }
    
    func getAutoDownloadPreview() -> DownloadPolicy {
        guard let result: String = securedStore.get(
            StoreKey.storage.autoDownloadPreview
        ) else {
            return autoDownloadPreviewDefaultState
        }
        
        return DownloadPolicy(rawValue: result) ?? autoDownloadPreviewDefaultState
    }
    
    func setAutoDownloadPreview(_ value: DownloadPolicy) {
        securedStore.set(value.rawValue, for: StoreKey.storage.autoDownloadPreview)
        autoDownloadPreviewState = value
    }
    
    func autoDownloadFullMediaPolicy() -> DownloadPolicy {
        autoDownloadFullMediaState
    }
    
    func getAutoDownloadFullMedia() -> DownloadPolicy {
        guard let result: String = securedStore.get(
            StoreKey.storage.autoDownloadFullMedia
        ) else {
            return autoDownloadFullMediaDefaultState
        }
        
        return DownloadPolicy(rawValue: result) ?? autoDownloadFullMediaDefaultState
    }
    
    func setAutoDownloadFullMedia(_ value: DownloadPolicy) {
        securedStore.set(value.rawValue, for: StoreKey.storage.autoDownloadFullMedia)
        autoDownloadFullMediaState = value
    }
}
