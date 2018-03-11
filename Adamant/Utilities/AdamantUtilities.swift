//
//  AdamantUtilities.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantUtilities {
	// MARK: Application version
	static var applicationVersion: String = {
		if let infoDictionary = Bundle.main.infoDictionary,
			let version = infoDictionary["CFBundleShortVersionString"] as? String,
			let build = infoDictionary["CFBundleVersion"] as? String {
			return "\(version) (\(build))"
		}
		
		return ""
	}()
	
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
	
	static func format(balance: UInt64) -> String {
		return currencyFormatter.string(from: NSNumber(value: from(uInt: balance)))!
	}
	
	static func format(balance: Double) -> String {
		return currencyFormatter.string(from: NSNumber(value: balance))!
	}
	
	static func format(balance: Decimal) -> String {
		return currencyFormatter.string(from: balance as NSNumber)!
	}
	
	static func format(balance: NSDecimalNumber) -> String {
		return currencyFormatter.string(from: balance as NSNumber)!
	}
	
	static func from(double: Double) -> UInt64 {
		return UInt64(double / currencyShift)
	}
	
	static func from(uInt: UInt64) -> Double {
		return Double(uInt) * currencyShift
	}
	
	static func validateAmount(amount: Double) -> Bool {
		if amount < currencyShift {
			return false
		}
		return true
	}
}


// MARK: - Validating Addresses and Passphrases
extension AdamantUtilities {
	static let addressRegexString = "^U([0-9]{6,20})$"
	static let passphraseRegexString = "^([a-z]* ){11}([a-z]*)$"
	static let passphraseRegex = try! NSRegularExpression(pattern: passphraseRegexString, options: [])
	static let addressRegex = try! NSRegularExpression(pattern: addressRegexString, options: [])
	
	/// Rules are simple:
	///
	/// - Leading uppercase U
	/// - From 6 to 20 numbers
	/// - No leading or trailing whitespaces
	static func validateAdamantAddress(address: String) -> Bool {
		return validate(string: address, with: addressRegex)
	}
	
	
	/// Rules are simple:
	///
	/// - No leading and/or trailing whitespaces
	/// - No UPPERCASE letters
	/// - No numbers
	/// - No -$%èçïäł- caracters
	/// - 12 words, splitted by a single whitespace
	/// - a-z
	static func validateAdamantPassphrase(passphrase: String) -> Bool {
		return validate(string: passphrase, with: passphraseRegex)
	}
	
	private static func validate(string: String, with regex: NSRegularExpression) -> Bool {
		let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
		
		return matches.count == 1
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


// MARK: - Hex
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
