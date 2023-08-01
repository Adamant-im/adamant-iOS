//
//  ComparableAttributedString.swift
//  Adamant
//
//  Created by Andrey Golubenko on 25.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public struct ComparableAttributedString: Equatable {
    public let string: NSAttributedString
    
    public init(string: NSAttributedString) {
        self.string = string
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.string.hash == rhs.string.hash else { return false }
        return lhs.string.string == rhs.string.string
    }
}
