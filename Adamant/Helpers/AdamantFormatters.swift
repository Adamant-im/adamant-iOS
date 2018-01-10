//
//  AdamantFormatters.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantFormatters {
	static let currencyShift: Double = 0.00_000_001
	static let currencyCode = "ADM"
	static let addressRegex = "^U([0-9]{6,})$"
	
	private init() { }
	
	static func format(balance: Int64) -> String {
		return "\(Double(balance) * currencyShift) \(currencyCode)"
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
	
	static func validateAdamantAddress(address: String) -> Bool {
		if let regex = try? NSRegularExpression(pattern: addressRegex, options: []) {
			let matches = regex.matches(in: address, options: [], range: NSRange(location: 0, length: address.count))
			
			return matches.count == 1
		} else {
			print("Wrong address regex: \(addressRegex)")
			return false
		}
	}
}
