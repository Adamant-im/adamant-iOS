//
//  DashWalletServiceIntegrationTests.swift
//  Adamant
//
//  Created by Christian Benua on 24.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant
import Swinject
import BitcoinKit
import CommonKit

final class DashWalletServiceIntegrationTests: XCTestCase {
    
    private var apiCoreMock: APICoreProtocolMock!
    private var lastTransactionStorageMock: DashLastTransactionStorageProtocolMock!
    private var dashApiServiceProtocolMock: DashApiServiceProtocolMock!
    private var sut: DashWalletService!
    
    override func setUp() {
        super.setUp()
        apiCoreMock = APICoreProtocolMock()
        dashApiServiceProtocolMock = DashApiServiceProtocolMock()
        dashApiServiceProtocolMock.api = DashApiCore(apiCore: apiCoreMock)
        lastTransactionStorageMock = DashLastTransactionStorageProtocolMock()
        
        sut = DashWalletService()
        sut.lastTransactionStorage = lastTransactionStorageMock
        sut.addressConverter = AddressConverterFactory().make(network: DashMainnet())
        sut.dashApiService = dashApiServiceProtocolMock
        sut.transactionFactory = BitcoinKitTransactionFactory()
    }
    
    override func tearDown() {
        apiCoreMock = nil
        dashApiServiceProtocolMock = nil
        lastTransactionStorageMock = nil
        sut = nil
        super.tearDown()
    }
    
    func test_createAndSendTransaction_createsValidTxIdAndHash() async throws {
        // given
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicGenericResult = APIResponseModel(result: .success(data), data: data, code: 200)
        }
        
        // when 1
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: "Xp6kFbogHMD4QRBDLQdqRp5zUgzmfj1KPn",
                amount: 0.01,
                fee: 0.0000001,
                comment: nil
            )
        })
        
        // then 1
        let transaction = try XCTUnwrap(result.value)
        XCTAssertEqual(transaction.serialized().hex, Constants.expectedTransactionHex)
        XCTAssertEqual(transaction.txID, Constants.expectedTransactionID)
        
        // given 2
        let txData = Constants.sendTransactionResponseData
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicGenericResult = APIResponseModel(result: .success(txData), data: txData, code: 200)
        }
        
        // when 2
        let result2 = await Result {
            try await self.sut.sendTransaction(transaction)
        }
        // then 3
        XCTAssertNil(result2.error)
        await apiCoreMock.isolated { mock in
            XCTAssertEqual(mock.invokedSendRequestBasicGenericCount, 2)
        }
    }
}

// MARK: Private

private extension DashWalletServiceIntegrationTests {
    func makeWallet() throws -> DashWallet {
        let privateKeyData = Constants.passphrase
            .data(using: .utf8)!
            .sha256()
        let privateKey = PrivateKey(
            data: privateKeyData,
            network: DashMainnet(),
            isPublicKeyCompressed: true
        )
        return try DashWallet(
            unicId: "DASHDASH",
            privateKey: privateKey,
            addressConverter: AddressConverterFactory().make(network: DashMainnet())
        )
    }
}

private enum Constants {
    
    static let passphrase = "village lunch say patrol glow first hurt shiver name method dolphin dead"
    
    static let expectedTransactionID = "d4cf3fde45d0e7ba855db9621bdc6da091856011d86f199bebd1937f7b63020a"
    
    static let expectedTransactionHex = "0100000001721f0c2437124acb8a20fea5af60908057b086118b240119adcb39c890b4c3a2010000006a473044022002e19bc62748ca3f34a6e5f1aeab31bb3dc43997792d9551e9b8c51a094abbae02200e3c9bde7c60326ef6984045a81304a9915e8fbce96de01813fe89886ef26453012102cd3dcbdfc1b77e54b3a8f273310806ab56b0c2463c2f1677c7694a89a713e0d0ffffffff0240420f00000000001976a914931ef5cbdad28723ba9596de5da1145ae969a71888acb695a905000000001976a91457f6f900ac7a7e3ccab712326cd7b85638fc15a888ac00000000"
    
    static let unspentTranscationsData = unspentTransactionsRawJSON.data(using: .utf8)!
    
    static let unspentTransactionsRawJSON: String = """
{
"result": [{
    "txid":"a2c3b490c839cbad1901248b1186b057809060afa5fe208acb4a1237240c1f72",
    "address": "Xp6kFbogHMD4QRBDLQdqRp5zUgzmfj1KPn",
    "outputIndex": 1,
    "script": "76a914931ef5cbdad28723ba9596de5da1145ae969a71888ac",
    "satoshis": 96000000,
    "height": 2209770
    }]
}
"""
    
    static let sendTransactionResponseData = sendTransactionResponseRawJSON.data(using: .utf8)!
    
    static let sendTransactionResponseRawJSON: String = """
{
  "result": "d4cf3fde45d0e7ba855db9621bdc6da091856011d86f199bebd1937f7b63020a"
}
"""
}
