//
//  ContributeViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

@MainActor
final class ContributeViewModel: ObservableObject {
    private let crashliticsService: CrashlyticsService
    
    @Published private(set) var state: ContributeState = .initial
    
    init(crashliticsService: CrashlyticsService) {
        self.crashliticsService = crashliticsService
        state.isCrashlyticsOn = crashliticsService.isCrashlyticsEnabled()
    }
    
    func setIsOn(_ value: Bool) {
        state.isCrashlyticsOn = value
        crashliticsService.setCrashlyticsEnabled(value)
    }
    
    func enableCrashButton() {
        withAnimation {
            state.isCrashButtonOn = true
        }
    }
    
    func simulateCrash() {
        fatalError("Test crash")
    }
}
