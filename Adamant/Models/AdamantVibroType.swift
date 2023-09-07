//
//  AdamantVibroType.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 07.09.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

enum AdamantVibroType {
    case light
    case rigid
    case heavy
    case medium
    case soft
    case selection
    case success
    case warning
    case error
    
    static var allCases: [AdamantVibroType] {
        return [.light, .rigid, .heavy, .medium, .soft, .selection, .success, .warning, .error]
    }
}
