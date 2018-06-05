//
//  AddressValidationTests.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 10.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class AddressValidationTests: XCTestCase {
	
    func testValidAddress() {
		let address = "U1234567890123456"
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address), AdamantUtilities.AddressValidationResult.valid)
    }
	
	func testMustBeLongerThanSixDigits() {
		let address = "U12345"
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address), AdamantUtilities.AddressValidationResult.invalid)
	}
	
	func testMustHaveLeadingU() {
		let address1 = "B12345678910"
		let address2 = "12345678910"
		let address3 = "1U2345678910"
		
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address1), AdamantUtilities.AddressValidationResult.invalid)
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address2), AdamantUtilities.AddressValidationResult.invalid)
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address3), AdamantUtilities.AddressValidationResult.invalid)
	}
	
	func testOnlyNumbers() {
		let address1 = "U12345d67890"
		let address2 = "U12345d7890_"
		
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address1), AdamantUtilities.AddressValidationResult.invalid)
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address2), AdamantUtilities.AddressValidationResult.invalid)
	}
	
	func testCapitalU() {
		let address = "u12345d67890"
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address), AdamantUtilities.AddressValidationResult.invalid)
	}
	
	func testNoWhitespaces() {
		let address1 = " U12345d67890"
		let address2 = "U12345d67890 "
		
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address1), AdamantUtilities.AddressValidationResult.invalid)
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: address2), AdamantUtilities.AddressValidationResult.invalid)
	}
	
	func testSystemAddresses() {
		let bounty = AdamantContacts.adamantBountyWallet.name
		let ico = AdamantContacts.adamantIco.name
		
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: bounty), AdamantUtilities.AddressValidationResult.system)
		XCTAssertEqual(AdamantUtilities.validateAdamantAddress(address: ico), AdamantUtilities.AddressValidationResult.system)
	}
}
