//
//  DelegatesGetTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/8/18.
//

import XCTest
@testable import LiskKit

class DelegatesGetTests: LiskTestCase {

    func testMainnetGetUsername() {
        let delegates = Delegates(client: mainNetClient)
        let response = tryRequest { delegates.delegates(username: andrewUsername, completionHandler: $0) }
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].username, andrewUsername)
    }

    func testMainnetGetPublicKey() {
        let delegates = Delegates(client: mainNetClient)
        let response = tryRequest { delegates.delegates(publicKey: andrewPublicKey, completionHandler: $0) }
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].username, andrewUsername)
    }
}
