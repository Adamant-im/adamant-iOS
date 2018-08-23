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
		let raw = self.description
		guard let decim = Decimal(string: raw) else {
			return 0
		}
		
		return Decimal(sign: decim.sign, exponent: exponent, significand: decim)
	}
}

extension BigUInt {
	func asDecimal(exponent: Int) -> Decimal {
		let raw = self.description
		guard let decim = Decimal(string: raw) else {
			return 0
		}
		
		return Decimal(sign: .plus, exponent: exponent, significand: decim)
	}
}
