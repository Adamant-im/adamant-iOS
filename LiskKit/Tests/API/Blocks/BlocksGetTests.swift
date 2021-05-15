//
//  BlocksGetTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/9/18.
//

import XCTest
@testable import LiskKit

class BlocksGetTests: LiskTestCase {

    func testMainnetGet() {
        let blockId = "6699130148421113207"
        let blocks = Blocks(client: mainNetClient)
        let response = tryRequest { blocks.blocks(id: blockId, completionHandler: $0) }
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].id, blockId)
    }
}
