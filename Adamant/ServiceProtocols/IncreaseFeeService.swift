//
//  IncreaseFeeService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

protocol IncreaseFeeService: AnyObject {
    func isIncreaseFeeEnabled(for id: String) -> Bool
    func setIncreaseFeeEnabled(for id: String, value: Bool)
}
