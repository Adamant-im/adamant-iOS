//
//  ContributeViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

@MainActor
final class ContributeViewModel: ObservableObject {
    private let crashliticsService: CrashlyticsService
    
    @Published private(set) var state: ContributeState = .initial
    
    init(crashliticsService: CrashlyticsService) {
        self.crashliticsService = crashliticsService
        state.isOn = crashliticsService.isCrashlyticsEnabled()
    }
    
    func setIsOn(_ value: Bool) {
        state.isOn = value
        crashliticsService.setCrashlyticsEnabled(value)
    }
    
    func simulateCrash() {
        fatalError("Test crash")
    }
}
