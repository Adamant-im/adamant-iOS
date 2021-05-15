//
//  SignaturesRegisterTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/10/18.
//

import XCTest
@testable import LiskKit

class SignaturesRegisterTests: LiskTestCase {

//    func testMainnetRegisterNoFunds() {
//        let signatures = Signatures(client: mainNetClient)
//        let response = tryRequestError { signatures.register(secondSecret: exampleSecret, secret: exampleSecret, completionHandler: $0) }
//        XCTAssertFalse(response.success)
//        XCTAssertEqual(response.message, "Account does not have enough LSK: 5549607903333983622L balance: 0")
//    }

    func testRegisterTransaction() {
        let (publicKey, _) = try! Crypto.keys(fromPassphrase: testSecondSecret)
        let asset = ["signature": ["publicKey": publicKey]]
        var transaction = LocalTransaction(.registerSecondPassphrase, amount: 0, timestamp: 51497510, asset: asset)
        try? transaction.sign(passphrase: testSecret)
        print(transaction)
        XCTAssertEqual(transaction.id, "6158495690989447317")
        XCTAssertEqual(transaction.amountBytes, [0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(transaction.recipientIdBytes, [0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(transaction.assetBytes, [141, 175, 155, 74, 131, 87, 53, 107, 128, 185, 85, 166, 13, 49, 211, 238, 165, 252, 141, 32, 109, 30, 166, 238, 45, 195, 197, 232, 117, 248, 52, 182])
        XCTAssertEqual(transaction.signatureBytes, [57, 245, 208, 241, 31, 217, 229, 107, 231, 143, 128, 58, 164, 154, 117, 29, 35, 145, 191, 119, 213, 90, 132, 219, 210, 69, 222, 23, 248, 102, 252, 73, 138, 249, 250, 149, 3, 56, 88, 149, 45, 105, 29, 73, 76, 242, 245, 117, 23, 122, 104, 95, 69, 201, 101, 119, 97, 174, 186, 157, 41, 235, 106, 11])
    }
}
