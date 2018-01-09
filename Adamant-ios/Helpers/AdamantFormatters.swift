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
	
	// TODO: replace description to 'pain is the ass' emoji, when Apple will add one is iOS 12
	/// Because 🖕🏻
	private static var magicAdamantTimeInterval: TimeInterval = {
		// JS handles moth as 0-based number, swift handles month as 1-based number.
		let components = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(abbreviation: "UTC"), year: 2017, month: 9, day: 2, hour: 17)
		return components.date!.timeIntervalSince1970
	}()
	
	static func decodeAdamantDate(timestamp: TimeInterval) -> Date {
		let interval = magicAdamantTimeInterval
		return Date(timeIntervalSince1970: timestamp + interval)
	}
}
