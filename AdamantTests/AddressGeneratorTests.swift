//
//  AddressGeneratorTests.swift
//  AdamantTests
//
//  Created by Andrey on 11.07.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

private struct PublicKeyAndAddress {
    let publicKey: String
    let address: String
}

class AddressGeneratorTests: XCTestCase {
    func test_0() {
        test(index: 0)
    }
    
    func test_1() {
        test(index: 1)
    }
    
    func test_2() {
        test(index: 2)
    }
    
    func test_3() {
        test(index: 3)
    }
    
    func test_4() {
        test(index: 4)
    }
    
    func test_5() {
        test(index: 5)
    }
    
    func test_6() {
        test(index: 6)
    }
    
    func test_7() {
        test(index: 7)
    }
    
    func test_8() {
        test(index: 8)
    }
    
    func test_9() {
        test(index: 9)
    }
}

private func test(index: Int) {
    let testData = testDataList[index]
    XCTAssertEqual(
        testData.address,
        AdamantUtilities.generateAddress(publicKey: testData.publicKey)
    )
}

private let testDataList: [PublicKeyAndAddress] = [
    .init(
        publicKey: "be2704af45c99dcfffa15166436532c2124f9fa9f982de301a133132c83bcf89",
        address: "U11308139377216585699"
    ),
    .init(
        publicKey: "48925aa0f16b59332426abb54b076b0d5ff641acaa89f504a8fc543ee5db13c5",
        address: "U7496679459594103068"
    ),
    .init(
        publicKey: "430a0ddc69f499c74ebc13a1904d6a1dea61188bba144ca394372494a9b4820f",
        address: "U3790996999662657220"
    ),
    .init(
        publicKey: "2664c578ca37249c9f26b7cd7f36f328eadec876ec13bca8dda59ee450e5e9d6",
        address: "U10726229737341939141"
    ),
    .init(
        publicKey: "e66deb0f23c1a790277a9ee9cbb640639aef94ce09e5118579e8801e3482b888",
        address: "U352167198766499766"
    ),
    .init(
        publicKey: "d7549e45aaac8c092628efa33253fe51d7561dcb5da00983f35579a58b3bf9cf",
        address: "U6181412134629172300"
    ),
    .init(
        publicKey: "45490d30f5de1acd8582c1839e8c3a92666da9b3f3b6dc1569dbccd1b0522a9d",
        address: "U8664044546816644023"
    ),
    .init(
        publicKey: "1cfcfeae065373f8b74f9a601aa83ed4521754ebf5cc8e63c3776c58f8ee35e3",
        address: "U13858077451564008890"
    ),
    .init(
        publicKey: "7e763ae1696a65c59ebe10f3203c1125ab3887eba97ac5e86b1bd7e61cd98a28",
        address: "U15771801756709905143"
    ),
    .init(
        publicKey: "0",
        address: "U1449310910991872227"
    )
]
