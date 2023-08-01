//
//  NodesListViewModel.swift
//  Adamant
//
//  Created by Andrey Golubenko on 01.08.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

@MainActor
final class NodesListViewModel: ObservableObject {
    @Published var state: NodesListViewState = .default
    
    private let coinsHealthCheckService: CoinsHealthCheckService
    
    nonisolated init(coinsHealthCheckService: CoinsHealthCheckService) {
        self.coinsHealthCheckService = coinsHealthCheckService
    }
    
    func reset() {}
}
