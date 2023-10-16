//
//  OptionSet+Extension.swift
//  
//
//  Created by Andrew G on 15.10.2023.
//

import Foundation

public extension OptionSet where RawValue: BinaryInteger, Element == Self  {
    func reduce<T>(_ initialResult: T, _ updateResult: (inout T, Self) -> Void) -> T {
        var result = initialResult
        var i: Int = .zero
        
        while i < rawValue.bitWidth {
            let option = Self.init(rawValue: rawValue & (1 << i))
            if contains(option) {
                updateResult(&result, option)
            }
            
            i += 1
        }
        
        return result
    }
}
