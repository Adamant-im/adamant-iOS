//
//  Task+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public extension Task where Success == Never, Failure == Never {
    static func sleep(interval: TimeInterval) async {
        try? await Task<Never, Never>.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
}
