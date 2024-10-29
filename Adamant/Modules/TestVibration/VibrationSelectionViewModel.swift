//
//  VibrationSelectionViewModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI
import Combine
import CommonKit

@MainActor
final class VibrationSelectionViewModel: ObservableObject {
    private let vibroService: VibroService
    private var subscriptions = Set<AnyCancellable>()
    
    @Published var type: AdamantVibroType?
    
    init(vibroService: VibroService) {
        self.vibroService = vibroService
        setup()
    }
}

private extension VibrationSelectionViewModel {
    func setup() {
        $type
            .compactMap { $0 }
            .sink { [weak vibroService] in vibroService?.applyVibration($0) }
            .store(in: &subscriptions)
    }
}
