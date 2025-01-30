//
//  KlyWalletServiceTests.swift
//  Adamant
//
//  Created by Christian Benua on 21.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant
import CommonKit
import LiskKit

final class KlyWalletServiceTests: XCTestCase {
    
    private var sut: KlyWalletService!
    private var transactionFactoryMock: KlyTransactionFactoryProtocolMock!
    private var apiServiceMock: KlyNodeApiServiceProtocolMock!
    
    override class func setUp() {
        super.setUp()
        applyURLSessionSwizzling()
    }
    
    override func setUp() {
        super.setUp()

        URLSessionSwizzlingHolder._stubbedUrlSessionConfiguration = Self.makeSessionConfig()
        sut = KlyWalletService()
        apiServiceMock = KlyNodeApiServiceProtocolMock()
        transactionFactoryMock = KlyTransactionFactoryProtocolMock()
        sut.klyTransactionFactory = transactionFactoryMock
        sut.klyNodeApiService = apiServiceMock
    }
    
    override func tearDown() {
        sut = nil
        transactionFactoryMock = nil
        apiServiceMock = nil
        MockURLProtocol.requestHandler = nil
        URLSessionSwizzlingHolder._stubbedUrlSessionConfiguration = nil
        super.tearDown()
    }
    
    func test_createTransaction_noWalletServiceThrowsError() async throws {
        // given
        sut.setWalletForTests(nil)
        
        // when
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: "recipient",
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_createTransaction_invalidRecipientAddress() async throws {
        // given
        sut.setWalletForTests(try makeWallet())
        
        // when
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.invalidKlyAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_createTransaction_createsValidTransaction() async throws {
        // given
        let wallet = try makeWallet()
        sut.setWalletForTests(wallet)
        
        // when
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validKlyAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then
        XCTAssertNil(result.error)
        checkMakeTransactionParameters(nonce: wallet.nonce)
        
        let transaction = try XCTUnwrap(result.value)
        checkTransaction(transaction: transaction)
    }
    
    func test_createAndSendTransaction() async throws {
        // given
        let wallet = try makeWallet()
        sut.setWalletForTests(wallet)
        
        // when 1
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validKlyAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then 1
        let transaction = try XCTUnwrap(result.value)
        var calledCompletion = false
        makeKlySendMock(expectedHash: transaction.getTxHash() ?? "") {
            calledCompletion = true
        }
        let result2 = await Swift.Result(catchingAsync: {
            try await self.sut.sendTransaction(transaction)
        })
        
        // when 2
        XCTAssertNil(result2.error)
        XCTAssertTrue(calledCompletion)
    }
}

// MARK: Private

private extension KlyWalletServiceTests {
    static func applyURLSessionSwizzling() {
        URLSession.swizzleInitializer()
    }
    
    static func makeSessionConfig() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
    
    func makeKlySendMock(expectedHash: String, _ onCall: @escaping () -> Void) {
        let prevHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = MockURLProtocol.combineHandlers(
            prevHandler
        ) { request in
            guard let stream = request.httpBodyStream else { return nil }
            let body = try JSONDecoder().decode(RpcRequestBody.self, from: Data(reading: stream))
            guard body.method == Constants.sendTransactionMethod else { return nil }
            
            XCTAssertEqual(body.params as? [String: String], ["transaction": expectedHash])
            onCall()
            return try self.makeResponseAndMockData(
                url: request.url!,
                klyResponse: KlyTransactionSubmitModel(transactionId: expectedHash)
            )
        }
    }
    
    func makeResponseAndMockData(
        url: URL,
        klyResponse: KlyTransactionSubmitModel
    ) throws -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let mockData = try JSONEncoder().encode(klyResponse)
        return (response, mockData)
    }
    
    func makeWallet() throws -> KlyWallet {
        let keyPair = try LiskKit.Crypto.keyPair(
            fromPassphrase: Constants.passphrase,
            salt: sut.salt
        )
        
        let address = LiskKit.Crypto.address(fromPublicKey: keyPair.publicKeyString)
        
        return KlyWallet(
            unicId: "KLYKLY",
            address: address,
            keyPair: keyPair,
            nonce: .zero,
            isNewApi: true
        )
    }
    
    func checkMakeTransactionParameters(
        nonce: UInt64,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(transactionFactoryMock.invokedCreateTxCount, 1, file: file, line: line)
        XCTAssertEqual(transactionFactoryMock.invokedCreateTxParameters?.amount, 10, file: file, line: line)
        XCTAssertEqual(transactionFactoryMock.invokedCreateTxParameters?.fee, 0.1, file: file, line: line)
        XCTAssertEqual(transactionFactoryMock.invokedCreateTxParameters?.nonce, nonce, file: file, line: line)
        XCTAssertEqual(
            transactionFactoryMock.invokedCreateTxParameters?.recipientAddressBinary,
            Constants.validKlyAddressBinary,
            file: file,
            line: line
        )
        XCTAssertEqual(
            transactionFactoryMock.invokedCreateTxParameters?.senderPublicKey,
            Constants.senderPublicKey,
            file: file,
            line: line
        )
        XCTAssertEqual(
            transactionFactoryMock.invokedCreateTxParameters?.comment,
            "",
            file: file,
            line: line
        )
    }
    
    func checkTransaction(
        transaction: TransactionEntity,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            transaction.senderPublicKey,
            Data(Constants.senderPublicKey.hexBytes()),
            file: file,
            line: line
        )
        XCTAssertEqual(
            transaction.params.recipientAddressBinary,
            Data(Constants.validKlyAddressBinary.hexBytes()),
            file: file,
            line: line
        )
        XCTAssertEqual(transaction.fee, UInt64(0.1 * pow(10, 8)), file: file, line: line)
        XCTAssertEqual(transaction.amountValue, 10, file: file, line: line)
        XCTAssertEqual(transaction.signatures, [Constants.expectedSignature], file: file, line: line)
    }
}

private enum Constants {
    
    static let passphrase = "village lunch say patrol glow first hurt shiver name method dolphin dead"
    
    static let senderPublicKey = "cb8bb87e2fa8050da0c193c74621698e1bba73851245b0bbbc45ec5905324c71"
        
    static let validKlyAddress = "klycufr5yusb5uphgbg8accfkka7tpe3x9zv872tq"
    
    static let validKlyAddressBinary = "1c3d25c61b32e04efcdf7e463f529974c96405a0"
    
    static let invalidKlyAddress = String(validKlyAddress[0..<38]) // valid KLY address is always 41 chars length
    
    static let expectedSignature = Data([
        176, 1, 177, 131, 119, 246, 146, 122, 152, 92, 10,
        239, 28, 204, 82, 249, 65, 5, 20, 54, 49, 18, 109, 220,
        229, 84, 94, 135, 143, 174, 230, 147, 166, 150, 67, 94,
        250, 75, 58, 28, 81, 175, 96, 207, 19, 228, 24, 38, 185,
        94, 46, 128, 88, 233, 97, 205, 30, 249, 233, 163, 148, 250, 76, 8
    ])
    
    static let sendTransactionMethod = "txpool_postTransaction"
}
