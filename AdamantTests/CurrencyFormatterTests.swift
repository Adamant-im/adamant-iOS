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
    func testInt() {
		let number = 123
		let format = "123 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testFracted() {
		let number = 123.5
		let format = "123.5 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testZeroFracted() {
		let number = 0.53
		let format = "0.53 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testVerySmallFracted() {
		let number = 0.00000007
		let format = "0.00000007 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}
	
	func testTooSmallFracted() {
		let number = 0.0000000699
		let format = "0.00000006 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)
		
		XCTAssertEqual(format, formatted)
	}

	func testLargeInt() {
		let number = 349034839840234
		let format = "349034839840234 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testLargeNumber() {
		let number = 9342034.5848984
		let format = "9342034.5848984 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

	func testNegative() {
		let number = -34.504
		let format = "-34.504 \(AdamantUtilities.currencyCode)"
		let formatted = AdamantUtilities.currencyFormatter.string(for: number)

		XCTAssertEqual(format, formatted)
	}

}
