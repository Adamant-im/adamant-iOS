//
//  IncreaseFeeService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol IncreaseFeeService: AnyObject {
    func isIncreaseFeeEnabled(for tokenUnicID: String) -> Bool
    func setIncreaseFeeEnabled(for tokenUnicID: String, value: Bool)
}
