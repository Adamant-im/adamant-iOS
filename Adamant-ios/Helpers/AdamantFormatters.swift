//
//  AdamantFormatters.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantFormatters {
	private static let balanceShift: Double = 100_000_000.0
	private static let currencyCode = "ADM"
	
	private init() { }
	
	static func format(balance: Int64) -> String {
		return "\(Double(balance) / balanceShift) \(currencyCode)"
	}
}
