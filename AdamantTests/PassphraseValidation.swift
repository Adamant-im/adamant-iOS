//
//  PassphraseValidation.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 22.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class PassphraseValidation: XCTestCase {
	
	func testValidPassphrase() {
		let passphrase = "bring hurry funny hamster fever observe cat property crawl mule course lizard"
		XCTAssertTrue(AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase))
	}
	
	func testTwelveWords() {
		let eleven = "one two three four five six seven eight nine ten eleven"
		let twelve = "one two three four five six seven eight nine ten eleven twelve"
		let thirteen = "one two three four five six seven eight nine ten eleven twelve thirteen"
		
		XCTAssertFalse(AdamantUtilities.validateAdamantPassphrase(passphrase: eleven))
		XCTAssertTrue(AdamantUtilities.validateAdamantPassphrase(passphrase: twelve))
		XCTAssertFalse(AdamantUtilities.validateAdamantPassphrase(passphrase: thirteen))
	}
}
