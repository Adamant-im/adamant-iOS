//
//  String+utilites.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

public extension String {
    static var empty: String = ""
    
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func checkAndReplaceSystemWallets() -> String {
        AdamantContacts(nodeNameKey: self)?.name
            ?? AdamantContacts(address: self)?.name
            ?? self
    }
    
    subscript(i: Int) -> Character {
        self[index(from: i)]
    }
    
    func index(from int: Int) -> Index {
        index(startIndex, offsetBy: int)
    }
    
    func substring(range: Range<Int>) -> String {
        let startIndex = index(from: range.lowerBound)
        let endIndex = index(from: range.upperBound)
        return String(self[startIndex ..< endIndex])
    }
}
