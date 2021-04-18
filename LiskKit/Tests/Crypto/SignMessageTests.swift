//
//  SignMessageTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 4/17/18.
//

import XCTest
@testable import LiskKit

class SignMessageTests: LiskTestCase {

    func testSignMessage() {
        let message = "Hello, World \(UUID().uuidString)"
        let signature = try! Crypto.signMessage(message, passphrase: exampleSecret)
        let verifiedYes = try! Crypto.verifyMessage(message, signature: signature, publicKey: examplePublicKey)
        let verifiedNo = try! Crypto.verifyMessage(message, signature: signature, publicKey: andrewPublicKey)
        XCTAssertTrue(verifiedYes)
        XCTAssertFalse(verifiedNo)
    }
}
