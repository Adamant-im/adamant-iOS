//
//  AdamantUtilities.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantUtilities {
	private init() { }
}


// MARK: - Currency
extension AdamantUtilities {
	static let currencyShift: Double = 0.00_000_001
	static let currencyCode = "ADM"
	
	static var currencyFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.numberStyle = .decimal
		formatter.roundingMode = .floor
		formatter.positiveFormat = "#.######## \(currencyCode)"
		return formatter
	}()
	
	static func format(balance: UInt) -> String {
		return currencyFormatter.string(from: NSNumber(value: from(uInt: balance)))!
	}
	
	static func format(balance: Double) -> String {
		return currencyFormatter.string(from: NSNumber(value: balance))!
	}
	
	static func from(double: Double) -> UInt {
		return UInt(double / currencyShift)
	}
	
	static func from(uInt: UInt) -> Double {
		return Double(uInt) * currencyShift
	}
}


// MARK: - Address
extension AdamantUtilities {
	static let addressRegex = "^U([0-9]{6,20})$"
	
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



// MARK: - Dates
extension AdamantUtilities {
	static func decodeAdamantDate(timestamp: TimeInterval) -> Date {
		return Date(timeIntervalSince1970: timestamp + magicAdamantTimeInterval)
	}
	
	private static var magicAdamantTimeInterval: TimeInterval = {
		// JS handles moth as 0-based number, swift handles month as 1-based number.
		let components = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(abbreviation: "UTC"), year: 2017, month: 9, day: 2, hour: 17)
		return components.date!.timeIntervalSince1970
	}()
}

// MARK: Hex
extension AdamantUtilities {
	static func getHexString(from bytes: [UInt8]) -> String {
		if bytes.count > 0 {
			return Data(bytes: bytes).reduce("") {$0 + String(format: "%02x", $1)}
		} else {
			return ""
		}
	}
	
	static func getBytes(from hex: String) -> [UInt8] {
		let hexa = Array(hex)
		return stride(from: 0, to: hex.count, by: 2).flatMap { UInt8(String(hexa[$0..<$0.advanced(by: 2)]), radix: 16) }
	}
}
