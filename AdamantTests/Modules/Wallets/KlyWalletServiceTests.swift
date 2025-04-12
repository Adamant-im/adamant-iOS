//
//  KlyWalletServiceTests.swift
//  Adamant
//
//  Created by Christian Benua on 21.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import LiskKit
import XCTest

@testable import Adamant

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
        // GIVEN
        sut.setWalletForTests(nil)

        // WHEN
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: "recipient",
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })

        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }

    func test_createTransaction_invalidRecipientAddress() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())

        // WHEN
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.invalidKlyAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })

        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }

    func test_createTransaction_createsValidTransaction() async throws {
        // GIVEN
        let wallet = try makeWallet()
        sut.setWalletForTests(wallet)
        //        let binaryAddress = try XCTUnwrap(LiskKit.Crypto.getBinaryAddressFromBase32(Constants.validKlyAddress))
        let expectedTransaction = TransactionEntity().createTx(
            amount: 10,
            fee: 0.1,
            nonce: 0,
            senderPublicKey: Constants.senderPublicKey,
            recipientAddressBinary: Constants.validKlyAddressBinary,
            comment: ""
        )
        transactionFactoryMock.given(
            .createTx(amount: .any, fee: .any, nonce: .any, senderPublicKey: .any, recipientAddressBinary: .any, comment: .any, willReturn: expectedTransaction)
        )

        // WHEN
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validKlyAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })

        // THEN
        XCTAssertNil(result.error)
        checkMakeTransactionParameters(nonce: wallet.nonce)

        let transaction = try XCTUnwrap(result.value)
        checkTransaction(transaction: transaction)
    }

    func test_createAndSendTransaction() async throws {
        // GIVEN
        let wallet = try makeWallet()
        sut.setWalletForTests(wallet)

        let binaryAddress = try XCTUnwrap(LiskKit.Crypto.getBinaryAddressFromBase32(Constants.validKlyAddress))
        let expectedTransaction = TransactionEntity().createTx(
            amount: 10,
            fee: 0.1,
            nonce: 0,
            senderPublicKey: "",
            recipientAddressBinary: binaryAddress,
            comment: ""
        )
        transactionFactoryMock.given(
            .createTx(amount: .any, fee: .any, nonce: .any, senderPublicKey: .any, recipientAddressBinary: .any, comment: .any, willReturn: expectedTransaction)
        )

        let apiClient = APIClient.mainnet

        let json = #"{"transactionId": "txId"}"#
        let submitModel = try JSONDecoder().decode(Transactions.TransactionSubmitModel.self, from: json.data(using: .utf8)!)
        apiServiceMock.given(
            .requestTransactionsApi(.any(((Transactions) async throws -> Transactions.TransactionSubmitModel).self), willReturn: .success(submitModel))
        )
        apiServiceMock.perform(
            .requestTransactionsApi(
                .any(((Transactions) async throws -> Transactions.TransactionSubmitModel).self),
                perform: { closure in
                    try await closure(Transactions.init(client: apiClient))
                }
            )
        )

        // WHEN 1
        let result = await Swift.Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validKlyAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })

        // THEN 1
        let transaction = try XCTUnwrap(result.value)
        var calledCompletion = false
        makeKlySendMock(expectedHash: transaction.getTxHash() ?? "") {
            calledCompletion = true
        }
        let result2 = await Swift.Result(catchingAsync: {
            try await self.sut.sendTransaction(transaction)
        })

        // WHEN 2
        XCTAssertNil(result2.error)
        XCTAssertTrue(calledCompletion)
    }
}

// MARK: Private

extension KlyWalletServiceTests {
    fileprivate static func applyURLSessionSwizzling() {
        URLSession.swizzleInitializer()
    }

    fileprivate static func makeSessionConfig() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }

    fileprivate func makeKlySendMock(expectedHash: String, _ onCall: @escaping () -> Void) {
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

    fileprivate func makeResponseAndMockData(
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

    fileprivate func makeWallet() throws -> KlyWallet {
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

    fileprivate func checkMakeTransactionParameters(
        nonce: UInt64,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        transactionFactoryMock.verify(
            .createTx(
                amount: .value(10),
                fee: .value(0.1),
                nonce: .value(nonce),
                senderPublicKey: .value(Constants.senderPublicKey),
                recipientAddressBinary: .value(Constants.validKlyAddressBinary),
                comment: .value("")
            ),
            count: 1
        )
    }

    fileprivate func checkTransaction(
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

    static let invalidKlyAddress = String(validKlyAddress[0..<38])  // valid KLY address is always 41 chars length

    static let expectedSignature = Data([
        176, 1, 177, 131, 119, 246, 146, 122, 152, 92, 10,
        239, 28, 204, 82, 249, 65, 5, 20, 54, 49, 18, 109, 220,
        229, 84, 94, 135, 143, 174, 230, 147, 166, 150, 67, 94,
        250, 75, 58, 28, 81, 175, 96, 207, 19, 228, 24, 38, 185,
        94, 46, 128, 88, 233, 97, 205, 30, 249, 233, 163, 148, 250, 76, 8
    ])

    static let sendTransactionMethod = "txpool_postTransaction"
}
