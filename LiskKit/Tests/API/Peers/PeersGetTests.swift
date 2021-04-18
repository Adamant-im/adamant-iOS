//
//  PeersGetTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/8/18.
//

import XCTest
@testable import LiskKit

class PeersGetTests: LiskTestCase {

    func testMainnetGet() {
        let peers = Peers(client: mainNetClient)
        let response = tryRequest { peers.peers(ip: "165.227.215.126", completionHandler: $0) }
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].version, "0.9.11")
    }
}
