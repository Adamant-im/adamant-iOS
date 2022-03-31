//
//  BigInt+Decimal.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import BigInt

extension BigInt {
    func asDecimal(exponent: Int) -> Decimal {
        let decim = Decimal(floatLiteral: Double(self))
        
        if exponent != 0 {
            return Decimal(sign: decim.sign, exponent: exponent, significand: decim)
        } else {
            return decim
        }
    }
}

extension BigUInt {
    func asDecimal(exponent: Int) -> Decimal {
        let decim = Decimal(string: String(self)) ?? 0
        
        if exponent != 0 {
            return Decimal(sign: .plus, exponent: exponent, significand: decim)
        } else {
            return decim
        }
    }
}
