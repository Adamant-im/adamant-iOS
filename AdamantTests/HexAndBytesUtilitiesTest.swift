//
//  HexAndBytesUtilitiesTest.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class HexAndBytesUtilitiesTest: XCTestCase {
	let bytes: [UInt8] = [144, 1, 73, 11, 22, 104, 22, 175, 117, 161, 90, 62, 43, 1, 116, 191, 227, 190, 61, 250, 166, 49, 71, 180, 247, 128, 237, 58, 185, 15, 254, 171]
	let hex = "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab"
	
	func testBytesToHex() {
		let freshHex = AdamantUtilities.getHexString(from: bytes)
		XCTAssertEqual(hex, freshHex)
	}
	
	func testHexToBytes() {
		let freshBytes = AdamantUtilities.getBytes(from: hex)
		XCTAssertEqual(bytes, freshBytes)
	}
}
