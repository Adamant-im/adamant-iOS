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
//        return (self as NSNumber).doubleValue
        return Double(self.description) ?? 0 // Fix issue with floation point number, that adds 0.00000000000002 value
    }
}
