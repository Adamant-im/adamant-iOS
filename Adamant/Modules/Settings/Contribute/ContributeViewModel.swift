//
//  ContributeViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import Combine
import CommonKit

@MainActor
final class ContributeViewModel: ObservableObject {
    private let crashliticsService: CrashlyticsService
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var state: ContributeState = .initial
    
    init(crashliticsService: CrashlyticsService) {
        self.crashliticsService = crashliticsService
        setup()
    }
    
    func enableCrashButton() {
        withAnimation {
            state.isCrashButtonOn = true
        }
    }
    
    func openLink(row: ContributeState.LinkRow) {
        state.safariURL = row.link.map { .init(id: $0.absoluteString, value: $0) }
    }
    
    func simulateCrash() {
        fatalError("Test crash")
    }
}

private extension ContributeViewModel {
    func setup() {
        state.isCrashlyticsOn = crashliticsService.isCrashlyticsEnabled()
        
        $state.map(\.isCrashlyticsOn)
            .removeDuplicates()
            .sink { [weak crashliticsService] in crashliticsService?.setCrashlyticsEnabled($0) }
            .store(in: &subscriptions)
    }
}
