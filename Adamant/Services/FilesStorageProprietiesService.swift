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
    private var isEnabledAutoDownloadPreview: Bool = true
    
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
        isEnabledAutoDownloadPreview = getEnabledAutoDownloadPreview()
    }
    
    private func userLoggedOut() {
        setEnabledAutoDownloadPreview(true)
    }
    
    // MARK: Update data
    
    func enabledAutoDownloadPreview() -> Bool {
        isEnabledAutoDownloadPreview
    }
    
    func getEnabledAutoDownloadPreview() -> Bool {
        guard let result: Bool = securedStore.get(
            StoreKey.storage.autoDownloadPreviewEnabled
        ) else {
            return true
        }
        
        return result
    }
    
    func setEnabledAutoDownloadPreview(_ value: Bool) {
        securedStore.set(value, for: StoreKey.storage.autoDownloadPreviewEnabled)
        isEnabledAutoDownloadPreview = value
    }
}
