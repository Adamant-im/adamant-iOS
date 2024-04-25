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

final class FilesStorageProprietiesService: FilesStorageProprietiesProtocol {
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    private var autoDownloadPreviewState: DownloadPolicy = .everybody
    private var autoDownloadFullMediaState: DownloadPolicy = .everybody

    // MARK: Lifecycle
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
                
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                self?.userLoggedIn()
            }
            .store(in: &notificationsSet)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedIn() {
        autoDownloadPreviewState = getAutoDownloadPreview()
        autoDownloadFullMediaState = getAutoDownloadFullMedia()
    }
    
    private func userLoggedOut() {
        setAutoDownloadPreview(.everybody)
        setAutoDownloadFullMedia(.everybody)
    }
    
    // MARK: Update data
    
    func autoDownloadPreviewPolicy() -> DownloadPolicy {
        autoDownloadPreviewState
    }
    
    func getAutoDownloadPreview() -> DownloadPolicy {
        guard let result: String = securedStore.get(
            StoreKey.storage.autoDownloadPreviewEnabled
        ) else {
            return .everybody
        }
        
        return DownloadPolicy(rawValue: result) ?? .everybody
    }
    
    func setAutoDownloadPreview(_ value: DownloadPolicy) {
        securedStore.set(value.rawValue, for: StoreKey.storage.autoDownloadPreviewEnabled)
        autoDownloadPreviewState = value
    }
    
    func autoDownloadFullMediaPolicy() -> DownloadPolicy {
        autoDownloadFullMediaState
    }
    
    func getAutoDownloadFullMedia() -> DownloadPolicy {
        guard let result: String = securedStore.get(
            StoreKey.storage.autoDownloadFullMediaEnabled
        ) else {
            return .everybody
        }
        
        return DownloadPolicy(rawValue: result) ?? .everybody
    }
    
    func setAutoDownloadFullMedia(_ value: DownloadPolicy) {
        securedStore.set(value.rawValue, for: StoreKey.storage.autoDownloadFullMediaEnabled)
        autoDownloadFullMediaState = value
    }
}
