//
//  DelegatesListTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/8/18.
//

import XCTest
@testable import LiskKit

class DelegatesListsTests: LiskTestCase {

    func testMainnetList() {
        let delegates = Delegates(client: mainNetClient)
        let response = tryRequest { delegates.delegates(limit: 5, completionHandler: $0) }
        XCTAssertEqual(response.data.count, 5)
    }

    func testMainnetSearch() {
        let delegates = Delegates(client: mainNetClient)
        let response = tryRequest { delegates.delegates(search: "andr", completionHandler: $0) }
        XCTAssertGreaterThanOrEqual(response.data.count, 1)
    }
}
