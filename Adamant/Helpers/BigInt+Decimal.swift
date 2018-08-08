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
	func asDecimal() -> Decimal {
		let raw = self.description
		guard let decim = Decimal(string: raw) else {
			return 0
		}
		
		return Decimal(sign: decim.sign, exponent: 8, significand: decim)
	}
}

extension BigUInt {
	func asDecimal() -> Decimal {
		let raw = self.description
		guard let decim = Decimal(string: raw) else {
			return 0
		}
		
		return Decimal(sign: .plus, exponent: 8, significand: decim)
	}
}
