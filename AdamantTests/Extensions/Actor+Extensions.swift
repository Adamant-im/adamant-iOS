//
//  Actor+Extensions.swift
//  Adamant
//
//  Created by Christian Benua on 10.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

extension Actor {
    func isolated<T: Sendable>(_ closure: (isolated Self) -> T) -> T {
        return closure(self)
    }
}
