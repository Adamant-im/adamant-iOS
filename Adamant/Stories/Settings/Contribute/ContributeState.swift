//
//  ContributeState.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 14.06.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

struct ContributeState: Equatable {
    var name: String
    var isOn: Bool
    
    static let initial = Self(
        name: NSLocalizedString(
            "AccountTab.Row.Contribute",
            comment: "'Contribute' row"),
        isOn: false
    )
}
