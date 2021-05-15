//
//  WebTokenTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 5/15/18.
//

import XCTest
@testable import LiskKit

class WebTokenTests: LiskTestCase {

    func testAuthenticationToken() {
        let token = try! WebToken(passphrase: exampleSecret)
        XCTAssertEqual(token.address, exampleAddress)
    }

    func testAuthenticationTokenOffset() {
        let token = try! WebToken(passphrase: exampleSecret, offset: -60)
        XCTAssertTrue(token.isExpired())
    }

    func testAuthenticationTokenToString() {
        let token = try! WebToken(passphrase: exampleSecret)
        let tokenString = token.tokenString()
        XCTAssertEqual(tokenString, "\(token.timestamp).\(token.publicKey).\(token.signature)")
    }

    func testAuthenticationTokenFromString() {
        let timestamp = Crypto.timeIntervalSinceGenesis()
        let signature = try! Crypto.signMessage("\(timestamp)", passphrase: exampleSecret)
        let tokenString = "\(timestamp).\(examplePublicKey).\(signature)"
        XCTAssertNoThrow(try WebToken(tokenString: tokenString))
    }

    func testAuthenticationTokenExpired() {
        let timestamp = Crypto.timeIntervalSinceGenesis(offset: -60)
        let signature = try! Crypto.signMessage("\(timestamp)", passphrase: exampleSecret)
        let tokenString = "\(timestamp).\(examplePublicKey).\(signature)"
        XCTAssertThrowsError(try WebToken(tokenString: tokenString))
    }

    func testAuthenticationTokenTimestampMismatch() {
        let timestamp = Crypto.timeIntervalSinceGenesis()
        let timestampExpired = Crypto.timeIntervalSinceGenesis(offset: -60)
        let signature = try! Crypto.signMessage("\(timestampExpired)", passphrase: exampleSecret)
        let tokenString = "\(timestamp).\(examplePublicKey).\(signature)"
        XCTAssertThrowsError(try WebToken(tokenString: tokenString))
    }

    func testAuthenticationTokenInvalidSecret() {
        let timestamp = Crypto.timeIntervalSinceGenesis()
        let signature = try! Crypto.signMessage("\(timestamp)", passphrase: testSecret)
        let tokenString = "\(timestamp).\(examplePublicKey).\(signature)"
        XCTAssertThrowsError(try WebToken(tokenString: tokenString))
    }
}
