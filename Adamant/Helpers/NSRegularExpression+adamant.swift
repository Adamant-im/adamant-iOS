//
//  NSRegularExpression+adamant.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    func perfectMatch(with string: String) -> Bool {
        return matches(in: string, options: [], range: NSRange(location: 0, length: string.count)).count == 1
    }
}
