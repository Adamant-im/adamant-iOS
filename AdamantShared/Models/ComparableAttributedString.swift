//
//  ComparableAttributedString.swift
//  Adamant
//
//  Created by Andrey Golubenko on 25.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct ComparableAttributedString: Equatable {
    let string: NSAttributedString
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.string.hash == rhs.string.hash else { return false }
        return lhs.string.string == rhs.string.string
    }
}
