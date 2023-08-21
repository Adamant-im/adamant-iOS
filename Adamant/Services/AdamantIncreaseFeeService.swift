//
//  AdamantIncreaseFeeService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine
import CommonKit

final class AdamantIncreaseFeeService: IncreaseFeeService {
    
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    @Atomic private var increaseFeeData: [String: Bool] = [:]
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    
    // MARK: Lifecycle
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedOut)
            .sink { [weak self] _ in
                self?.userLoggedOut()
            }
            .store(in: &notificationsSet)
        
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                self?.userLoggedIn()
            }
            .store(in: &notificationsSet)
    }
    
    // MARK: Notification actions
    
    private func userLoggedIn() {
        increaseFeeData = getIncreaseFeeDictionary()
    }
    
    private func userLoggedOut() {
        securedStore.remove(StoreKey.increaseFee.increaseFee)
        increaseFeeData = [:]
    }
    
    // MARK: Check
    
    func isIncreaseFeeEnabled(for tokenUnicID: String) -> Bool {
        return increaseFeeData[tokenUnicID] ?? false
    }
    
    func setIncreaseFeeEnabled(for tokenUnicID: String, value: Bool) {
        $increaseFeeData.mutate {
            $0[tokenUnicID] = value
            securedStore.set($0, for: StoreKey.increaseFee.increaseFee)
        }
    }
    
    private func getIncreaseFeeDictionary() -> [String: Bool] {
        guard let result: [String: Bool] = securedStore.get(StoreKey.increaseFee.increaseFee) else {
            return [:]
        }
        
        return result
    }
}
