//
//  TestTools.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 13.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class TestTools {
    static func LoadJsonAndDecode<T: Decodable>(filename: String) -> T {
        let rawJson = TestTools.LoadJson(named: filename)
        
        return try! JSONDecoder().decode(T.self, from: rawJson)
    }
    
    static func LoadJson(named filename: String) -> Data {
        return TestTools.LoadResource(filename: filename, withExtension: "json")
    }
    
    static func LoadResource(filename: String, withExtension ext: String) -> Data {
        let url = Bundle(for: self).url(forResource: filename, withExtension: ext)
        return try! Data(contentsOf: url!)
    }
}
