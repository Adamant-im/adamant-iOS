//
//  AdamantLocalized.swift
//  Adamant
//
//  Created by Anokhov Pavel on 30/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public extension String {
    enum adamant {}
    
    static func localized(_ key: String, comment: String = .empty) -> String {
        NSLocalizedString(key, bundle: .module, comment: comment)
    }
}
