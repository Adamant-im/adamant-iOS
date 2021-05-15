//
//  BlocksListTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/9/18.
//

import XCTest
@testable import LiskKit

class BlocksListTests: LiskTestCase {

    func testMainnetGet() {
        let blocks = Blocks(client: mainNetClient)
        let response = tryRequest { blocks.blocks(limit: 5, completionHandler: $0) }
        XCTAssertEqual(response.data.count, 5)
    }
}
