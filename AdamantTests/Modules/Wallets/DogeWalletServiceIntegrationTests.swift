//
//  DogeWalletServiceIntegrationTests.swift
//  Adamant
//
//  Created by Christian Benua on 20.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant
import Swinject
import BitcoinKit
import CommonKit

final class DogeWalletServiceIntegrationTests: XCTestCase {
    
    private var apiCoreMock: APICoreProtocolMock!
    private var dogeApiServiceProtocolMock: DogeApiServiceProtocolMock!
    private var sut: DogeWalletService!
    
    override func setUp() {
        super.setUp()
        apiCoreMock = APICoreProtocolMock()
        dogeApiServiceProtocolMock = DogeApiServiceProtocolMock()
        dogeApiServiceProtocolMock._api = DogeApiCore(apiCore: apiCoreMock)
        
        sut = DogeWalletService()
        sut.addressConverter = AddressConverterFactory().make(network: DogeMainnet())
        sut.dogeApiService = dogeApiServiceProtocolMock
        sut.btcTransactionFactory = BitcoinKitTransactionFactory()
    }
    
    override func tearDown() {
        apiCoreMock = nil
        dogeApiServiceProtocolMock = nil
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
                recipient: Constants.recipient,
                amount: 9,
                fee: 1,
                comment: nil
            )
        })
        
        // then 1
        let transaction = try XCTUnwrap(result.value)
        XCTAssertEqual(transaction.serialized().hex, Constants.expectedTransactionHex)
        XCTAssertEqual(transaction.txID, Constants.expectedTransactionID)
        
        // given 2
        let txData = try XCTUnwrap(transaction.txID.data(using: .utf8))
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
    
    private func makeWallet() throws -> DogeWallet {
        let privateKeyData = Constants.passphrase
            .data(using: .utf8)!
            .sha256()
        let privateKey = PrivateKey(
            data: privateKeyData,
            network: DogeMainnet(),
            isPublicKeyCompressed: true
        )
        return try DogeWallet(
            unicId: Constants.tokenId,
            privateKey: privateKey,
            addressConverter: AddressConverterFactory().make(network: DogeMainnet())
        )
    }
}

private enum Constants {
    
    static let passphrase = "village lunch say patrol glow first hurt shiver name method dolphin dead"
    
    static let recipient = "DPCnnvzngz9AcpToiM7Y8qLewEDtP7jN8T"
    
    static let tokenId = "DOGEDOGE"
    
    static let expectedTransactionID = "4f9700bca38cce8f442ba0ebf6b2c1b95d235854cabb797fb1178499a5403c7a"
    
    static let expectedTransactionHex = "0100000001010000006b483045022100c54ae687dfaa6e910eaf2d40ec755cc11eb1263de38cbe4a5b48b1a13c6d113c022043cce15981221cef35fbcfe0a35ad9a9a218257acb854d1dc0f6e0ebbe892c2d012102cd3dcbdfc1b77e54b3a8f273310806ab56b0c2463c2f1677c7694a89a713e0d0ffffffff0200e9a435000000001976a914c6251d0e16c0e1946b745b69caa3a7c36014381088ac00362634f28623001976a91457f6f900ac7a7e3ccab712326cd7b85638fc15a888ac00000000"
    
    static let unspentTranscationsData = unspentTranscationsRawJSON.data(using: .utf8)!
    
    static let unspentTranscationsRawJSON: String = """
[
  {
    "txid": "1",
    "vout": 1,
    "amount": 100000000,
    "confirmations": 1
  },
  {
    "txid": "1",
    "vout": 2,
    "amount": 100000000,
    "confirmations": 1
  },
  {
    "txid": "1",
    "vout": 3,
    "amount": 200000000,
    "confirmations": 0
  }
]
"""
}
