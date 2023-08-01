//
//  Double+adamant.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 03.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public extension Double {
    func format(with formatter: NumberFormatter) -> String {
        let number = NSNumber(value: self)
        let formattedValue = formatter.string(from: number) ?? "\(number)"
        return formattedValue
    }
}
