//
//  WordList.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

/// Word dictionaries
class WordList {
    /// English words dictionary
    static var english: [String.SubSequence] = {
        let url = Bundle(for: Mnemonic.self).url(forResource: "english", withExtension: "txt")
        let data = try! Data(contentsOf: url!)
        let raw = String(data: data, encoding: .utf8)!
        
        return raw.split(separator: "\n")
    }()
    
    private init() {}
}
