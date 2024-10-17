//
//  PartnerQRService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 28.10.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import Combine

final class AdamantPartnerQRService: PartnerQRService, @unchecked Sendable {
    
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
  
    // MARK: Lifecycle
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        NotificationCenter.default
            .notifications(named: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedOut() {
        setIncludeNameEnabled(true)
        setIncludeURLEnabled(true)
    }
    
    // MARK: Update data
    
    func setIncludeNameEnabled(_ value: Bool) {
        securedStore.set(value, for: StoreKey.partnerQR.includeNameEnabled)
    }
    
    func isIncludeNameEnabled() -> Bool {
        guard let result: Bool = securedStore.get(
            StoreKey.partnerQR.includeNameEnabled
        ) else {
            return true
        }
        
        return result
    }
    
    func setIncludeURLEnabled(_ value: Bool) {
        securedStore.set(value, for: StoreKey.partnerQR.includeURLEnabled)
    }
    
    func isIncludeURLEnabled() -> Bool {
        guard let result: Bool = securedStore.get(
            StoreKey.partnerQR.includeURLEnabled
        ) else {
            return true
        }
        
        return result
    }
}
