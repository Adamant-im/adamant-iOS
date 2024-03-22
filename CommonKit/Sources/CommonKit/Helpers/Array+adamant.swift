//
//  Array+adamant.swift
//
//
//  Created by Stanislav Jelezoglo on 21.03.2024.
//

import Foundation

public extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
