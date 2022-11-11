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

    func testBTCValidation1() {
        let s = BtcWalletService()
        XCTAssertEqual(s.isValid(bitcoinAddress: "1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62i"), true)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62j"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1Q1pE5vPGEEMqRcVRMbtBK842Y6Pzo6nK9"), true)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62X"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1ANNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62i"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1A Na15ZQXAZUgFiqJ2i7Z2DPU2J6hW62i"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "BZbvjr"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "i55j"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62!"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62iz"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62izz"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1Q1pE5vPGEEMqRcVRMbtBK842Y6Pzo6nJ9"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "1AGNa15ZQXAZUgFiqJ2i7Z2DPU2J6hW62I"), false)
    }

    func testBTCValidation3() {
        let s = BtcWalletService()
        XCTAssertEqual(s.isValid(bitcoinAddress: "3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy"), true)
    }

    func testBTCValidationBC1() {
        let s = BtcWalletService()
        XCTAssertEqual(s.isValid(bitcoinAddress: "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"), true)
        XCTAssertEqual(s.isValid(bitcoinAddress: "BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4"), true)
        XCTAssertEqual(s.isValid(bitcoinAddress: "bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7k7grplx"), true)
        XCTAssertEqual(s.isValid(bitcoinAddress: "BC1SW50QA3JX3S"), true)
        XCTAssertEqual(s.isValid(bitcoinAddress: "bc1zw508d6qejxtdg4y5r3zarvaryvg6kdaj"), true)
        XCTAssertEqual(s.isValid(bitcoinAddress: "bc10w508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kw5rljs90"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "BC1QR508D6QEJXTDG4Y5R3ZARVARYV98GJ9P"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "bc1rw5uspcuh"), false)
        XCTAssertEqual(s.isValid(bitcoinAddress: "bc1gmk9yu"), false)
    }

}
