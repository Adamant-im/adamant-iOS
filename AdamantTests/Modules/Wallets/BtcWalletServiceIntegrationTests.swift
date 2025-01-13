//
//  BtcWalletServiceIntegrationTests.swift
//  Adamant
//
//  Created by Christian Benua on 13.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant
import Swinject
import BitcoinKit
import CommonKit

final class BtcWalletServiceIntegrationTests: XCTestCase {
    
    private var apiCoreMock: APICoreProtocolMock!
    private var btcApiServiceProtocolMock: BtcApiServiceProtocolMock!
    private var sut: BtcWalletService!
    
    override func setUp() {
        super.setUp()
        apiCoreMock = APICoreProtocolMock()
        btcApiServiceProtocolMock = BtcApiServiceProtocolMock()
        btcApiServiceProtocolMock.api = BtcApiCore(apiCore: apiCoreMock)
        
        sut = BtcWalletService()
        sut.addressConverter = AddressConverterFactory().make(network: .mainnetBTC)
        sut.btcApiService = btcApiServiceProtocolMock
        sut.btcTransactionFactory = BitcoinKitTransactionFactory()
    }
    
    override func tearDown() {
        apiCoreMock = nil
        btcApiServiceProtocolMock = nil
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
                recipient: "1K4hFg49PaEt5pHCym7yb5B446Vb3roSMp",
                amount: 0.00009,
                fee: 0.00002159542,
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
    
    private func makeWallet() throws -> BtcWallet {
        let privateKeyData = Constants.passphrase
            .data(using: .utf8)!
            .sha256()
        let privateKey = PrivateKey(
            data: privateKeyData,
            network: .mainnetBTC,
            isPublicKeyCompressed: true
        )
        return try BtcWallet(
            unicId: "BTCBTC",
            privateKey: privateKey,
            addressConverter: AddressConverterFactory().make(network: .mainnetBTC)
        )
    }
}

private enum Constants {
    
    static let passphrase = "village lunch say patrol glow first hurt shiver name method dolphin dead"
    
    static let expectedTransactionID = "e9e99b0d38e3b3fc362a3a9a2809807af179cbaaff59ae7f9ddb3ed30a4f9582"
    
    static let expectedTransactionHex = "0100000001a0d73e3bd0aa2025d91eabd8512d5e19ad80752892f415480f75b97966b06f0e010000006a47304402200f8908e3a4b1c3ab181fa875c15dc8816ec29298a74e78122000d4e08bced3a2022016767a16bb9ea315a9ea9a8536d39bd3e6e8dce3594cf5b17c4576f7bfc39140012102cd3dcbdfc1b77e54b3a8f273310806ab56b0c2463c2f1677c7694a89a713e0d0ffffffff0228230000000000001976a914c6251d0e16c0e1946b745b69caa3a7c36014381088ac38560200000000001976a91457f6f900ac7a7e3ccab712326cd7b85638fc15a888ac00000000"
    
    static let unspentTranscationsData = unspentTranscationsRawJSON.data(using: .utf8)!
        
    static let unspentTranscationsRawJSON: String = """
[{
    "txid":"0e6fb06679b9750f4815f492287580ad195e2d51d8ab1ed92520aad03b3ed7a0",
    "vout":1,
    "status":{
        "confirmed":true,
        "block_height":879091,
        "block_hash":"00000000000000000001e0da09b0792ff69dcd98af264b1750cbf9ef2deab73d",
        "block_time":1736786953},
        "value":164303
}]
"""
}
