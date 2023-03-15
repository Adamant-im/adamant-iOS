//
//  AdamantIncreaseFeeService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation
import Combine

final class AdamantIncreaseFeeService: IncreaseFeeService {
    
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    // MARK: Proprieties
    
    private var data: [String: Bool] = [:]
    private var notificationsSet: Set<AnyCancellable> = []
    
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
        data = getIncreaseFeeDictionary()
    }
    
    private func userLoggedOut() {
        securedStore.remove(StoreKey.increaseFee.increaseFee)
        data = [:]
    }
    
    // MARK: Check
    
    func isIncreaseFeeEnabled(for id: String) -> Bool {
        return data[id] ?? false
    }
    
    func setIncreaseFeeEnabled(for id: String, value: Bool) {
        data[id] = value
        securedStore.set(data, for: StoreKey.increaseFee.increaseFee)
    }
    
    private func getIncreaseFeeDictionary() -> [String: Bool] {
        guard let result: [String: Bool] = securedStore.get(StoreKey.increaseFee.increaseFee) else {
            return [:]
        }
        
        return result
    }
}
