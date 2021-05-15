//
//  TransactionsGetTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/2/18.
//

import XCTest
@testable import LiskKit

class TransactionsGetTests: LiskTestCase {

    func testMainnetGet() {
        let id = "10861152394901264352"
        let transactions = Transactions(client: mainNetClient)
        let response = tryRequest { transactions.transactions(id: id, completionHandler: $0) }
        XCTAssertEqual(response.data.count, 1)
        XCTAssertEqual(response.data[0].id, id)
    }
}
