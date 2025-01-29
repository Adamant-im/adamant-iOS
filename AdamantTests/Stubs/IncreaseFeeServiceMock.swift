//
//  IncreaseFeeServiceMock.swift
//  Adamant
//
//  Created by Christian Benua on 15.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant

final class IncreaseFeeServiceMock: IncreaseFeeService {
    
    var stubbedIncreaseFeeEnabled: Bool = false
    func isIncreaseFeeEnabled(for tokenUnicID: String) -> Bool {
        return stubbedIncreaseFeeEnabled
    }
    
    func setIncreaseFeeEnabled(for tokenUnicID: String, value: Bool) {}
}
