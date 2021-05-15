//
//  AccountsPublicKeyTests.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import XCTest
@testable import LiskKit

class AccountsPublicKeyTests: LiskTestCase {

    func testMainnetPublicKey() {
        let accounts = Accounts(client: mainNetClient)
        let response = tryRequest { accounts.accounts(address: andrewAddress, completionHandler: $0) }
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].publicKey, andrewPublicKey)
    }
}
