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
    let id: String
    
    init(string: NSAttributedString, id: String) {
        self.string = string
        self.id = id
    }
    
    init(string: NSAttributedString) {
        self.string = string
        self.id = ""
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.string.hash == rhs.string.hash else { return false }
        return lhs.string.string == rhs.string.string
    }
}