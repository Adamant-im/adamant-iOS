//
//  CodeEntryService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 15.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Combine
import UIKit
import CommonKit

protocol CodeEntryProtocol {
    func attemptCodeEntry()
    func canCodeEntry() -> Bool
    
    var remainingAttemptsPublisher: Published<Int>.Publisher {
        get
    }
}

final class CodeEntryService: CodeEntryProtocol {
    // MARK: Dependencies
    
    let securedStore: SecuredStore
    
    private let maxAttempts: Int = 5
    private var cancellables = Set<AnyCancellable>()
    
    @Published private var remainingAttempts: Int = 5
    @Atomic private var notificationsSet: Set<AnyCancellable> = []
    
    var remainingAttemptsPublisher: Published<Int>.Publisher {
        $remainingAttempts
    }
    
    init(securedStore: SecuredStore) {
        self.securedStore = securedStore
        self.remainingAttempts = getRemainingAttempts()
        
        addObservers()
    }
    
    func canCodeEntry() -> Bool {
        remainingAttempts > .zero
    }
    
    func attemptCodeEntry() {
        guard canCodeEntry() else { return }
        
        remainingAttempts -= 1
        setRemainingAttempts(value: remainingAttempts)
    }
}

private extension CodeEntryService {
    func addObservers() {
        NotificationCenter.default
            .publisher(for: .AdamantAccountService.userLoggedIn)
            .sink { [weak self] _ in
                guard self?.remainingAttempts != self?.maxAttempts else { return }
                self?.resetRemainingAttempts()
            }
            .store(in: &notificationsSet)
    }
    
    func getRemainingAttempts() -> Int {
        guard let result: Int = securedStore.get(
            StoreKey.login.remainingAttempts
        ) else {
            return maxAttempts
        }
        
        return result
    }
    
    func setRemainingAttempts(value: Int) {
        securedStore.set(value, for: StoreKey.login.remainingAttempts)
    }
    
    func resetRemainingAttempts() {
        setRemainingAttempts(value: maxAttempts)
    }
}
