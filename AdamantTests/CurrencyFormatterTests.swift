//
//  CurrencyFormatterTests.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class CurrencyFormatterTests: XCTestCase {
	var decimalSeparator: String = Locale.current.decimalSeparator!
	
    func testInt() {
		let number = Decimal(123)
		let format = "123 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testFracted() {
		let number = Decimal(123.5)
		
		let format = "123\(decimalSeparator)5 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testZeroFracted() {
		let number = Decimal(0.53)
		let format = "0\(decimalSeparator)53 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testVerySmallFracted() {
		let number = Decimal(0.00000007)
		let format = "0\(decimalSeparator)00000007 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}
	
	func testTooSmallFracted() {
		let number = Decimal(0.0000000699)
		let format = "0\(decimalSeparator)00000006 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)
		
		XCTAssertEqual(format, formatted)
	}

	func testLargeInt() {
		let number = Decimal(34903483984)
		let format = "34903483984 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)
		
		XCTAssertEqual(format, formatted)
	}

	func testLargeNumber() {
		let number = Decimal(9342034.5848984)
		let format = "9342034\(decimalSeparator)5848984 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testNegative() {
		let number = Decimal(-34.504)
		let format = "-34\(decimalSeparator)504 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}
}
