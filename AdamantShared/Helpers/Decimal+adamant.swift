//
//  Decimal+adamant.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension Decimal {
    func shiftedFromAdamant() -> Decimal {
        return Decimal(sign: self.isSignMinus ? .minus : .plus, exponent: AdamantUtilities.admCurrencyExponent, significand: self)
    }
    
    func shiftedToAdamant() -> Decimal {
        return Decimal(sign: self.isSignMinus ? .minus : .plus, exponent: -AdamantUtilities.admCurrencyExponent, significand: self)
    }
    
    var doubleValue: Double {
        // NSDecimalNumber loses decimal precision when deserializing numbers by doubleValue.
        // Try to get string value and deserialize it
        let decimalValue = NSDecimalNumber(decimal: self)
        let stringValue = decimalValue.stringValue
        guard let doubleValue = Double(stringValue) else { return Double(truncating: decimalValue) }
        return doubleValue
    }
}
