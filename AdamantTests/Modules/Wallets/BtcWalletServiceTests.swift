//
//  BtcWalletServiceTests.swift
//  Adamant
//
//  Created by Christian Benua on 09.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import BitcoinKit
import CommonKit
import SwiftyMocky
import Swinject
import XCTest

@testable import Adamant

final class BtcWalletServiceTests: XCTestCase {

    private var addressConverterMock: AddressConverterMock!
    private var apiCoreMock: APICoreProtocolMock!
    private var btcApiServiceProtocolMock: BtcApiServiceProtocolMock!
    private var transactionFactoryMock: BitcoinKitTransactionFactoryProtocolMock!
    private var sut: BtcWalletService!

    override func setUp() {
        super.setUp()
        addressConverterMock = AddressConverterMock()
        apiCoreMock = APICoreProtocolMock()
        btcApiServiceProtocolMock = BtcApiServiceProtocolMock()
        btcApiServiceProtocolMock.api = BtcApiCore(apiCore: apiCoreMock)

        sut = BtcWalletService()
        sut.addressConverter = addressConverterMock
        sut.btcApiService = btcApiServiceProtocolMock
        transactionFactoryMock = BitcoinKitTransactionFactoryProtocolMock()
        Matcher.default.register((AddressProtocol & QRCodeConvertible).self) {
            $0.lockingScript == $1.lockingScript
                && $0.lockingScriptPayload == $1.lockingScriptPayload
                && $0.scriptType == $1.scriptType
                && $0.stringValue == $1.stringValue
                && $0.qrcodeString == $1.qrcodeString
        }
        sut.btcTransactionFactory = transactionFactoryMock
    }

    override func tearDown() {
        addressConverterMock = nil
        apiCoreMock = nil
        btcApiServiceProtocolMock = nil
        transactionFactoryMock = nil
        sut = nil
        super.tearDown()
    }

    func test_createTransaction_noWalletThrowsError() async throws {
        // GIVEN
        sut.setWalletForTests(nil)

        // WHEN
        let result = await Result(catchingAsync: {
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

    func test_createTransaction_accountNotFoundThrowsError() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        addressConverterMock.given(.convert(address: .any, willThrow: NSError()))

        // WHEN
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: "recipient",
                amount: 10,
                fee: 1,
                comment: nil
            )
        })

        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }

    func test_createTransaction_notEnoughMoneyThrowsError() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.given(
                .sendRequestBasic(
                    origin: .any,
                    path: .any,
                    method: .any,
                    parameters: .any([String: String].self),
                    encoding: .any,
                    timeout: .any,
                    downloadProgress: .any,
                    willReturn: APIResponseModel(
                        result: .success(data),
                        data: data,
                        code: 200
                    )
                )
            )
        }
        addressConverterMock.given(.convert(address: .any, willReturn: try makeDefaultAddress()))

        // WHEN
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: "recipient",
                amount: 30 / BtcWalletService.multiplier,
                fee: 1 / BtcWalletService.multiplier,
                comment: nil
            )
        })

        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notEnoughMoney)
    }

    func test_createTransaction_badUnspentTransactionResponseDataThrowsError() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsCorruptedData
        await apiCoreMock.isolated { mock in
            mock.given(
                .sendRequestBasic(
                    origin: .any,
                    path: .any,
                    method: .any,
                    parameters: .any([String: String].self),
                    encoding: .any,
                    timeout: .any,
                    downloadProgress: .any,
                    willReturn: APIResponseModel(
                        result: .success(data),
                        data: data,
                        code: 200
                    )
                )
            )
        }
        addressConverterMock.given(.convert(address: .any, willReturn: try makeDefaultAddress()))

        // WHEN
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: "recipient",
                amount: 30 / BtcWalletService.multiplier,
                fee: 1 / BtcWalletService.multiplier,
                comment: nil
            )
        })

        // THEN
        switch result.error as? WalletServiceError {
        case .internalError?:
            break
        default:
            XCTFail("Expected `internalError`, but got \(String(describing: result.error))")
        }
    }

    func test_createTransaction_enoughMoneyReturnsRealTransaction() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet(address: Constants.anotherBtcAddress))
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.given(
                .sendRequestBasic(
                    origin: .any,
                    path: .any,
                    method: .any,
                    parameters: .any([String: String].self),
                    encoding: .any,
                    timeout: .any,
                    downloadProgress: .any,
                    willReturn: APIResponseModel(
                        result: .success(data),
                        data: data,
                        code: 200
                    )
                )
            )
        }
        let expectedToAddress = try makeDefaultAddress()
        let changeAddress = try XCTUnwrap(sut.btcWallet?.addressEntity)
        let expectedTransaction = BitcoinKit.Transaction.createNewTransaction(
            toAddress: expectedToAddress,
            amount: 10,
            fee: 1,
            changeAddress: changeAddress,
            utxos: Constants.expectedUnspentTransactions,
            lockTime: 0,
            keys: []
        )
        addressConverterMock.given(.convert(address: .any, willReturn: expectedToAddress))
        transactionFactoryMock.given(
            .createTransaction(
                toAddress: .any,
                amount: .any,
                fee: .any,
                changeAddress: .any,
                utxos: .any,
                lockTime: .any,
                keys: .any,
                willReturn: expectedTransaction
            )
        )

        // WHEN
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: "recipient",
                amount: 10 / BtcWalletService.multiplier,
                fee: 1 / BtcWalletService.multiplier,
                comment: nil
            )
        })

        // THEN
        XCTAssertNil(result.error)
        XCTAssertEqual(result.value, Constants.expectedTransaction)

        transactionFactoryMock.verify(
            .createTransaction(
                toAddress: .value(expectedToAddress),
                amount: .value(10),
                fee: .value(1),
                changeAddress: .value(changeAddress),
                utxos: .value(Constants.expectedUnspentTransactions),
                lockTime: .any,
                keys: .any
            )
        )
    }

    func test_sendTransaction_failIfTxIdCorrupted() async throws {
        // GIVEN
        let txData = try XCTUnwrap(Constants.anotherTransactionId.data(using: .utf8))
        await apiCoreMock.isolated { mock in
            mock.given(
                .sendRequestBasic(
                    origin: .any,
                    path: .any,
                    method: .any,
                    parameters: .any([String: String].self),
                    encoding: .any,
                    timeout: .any,
                    downloadProgress: .any,
                    willReturn: APIResponseModel(
                        result: .success(txData),
                        data: txData,
                        code: 200
                    )
                )
            )
        }

        // WHEN
        let result = await Result {
            try await self.sut.sendTransaction(BitcoinKit.Transaction.deserialize(Data(hex: Constants.transactionHex)!))
        }

        // THEN
        XCTAssertEqual(
            result.error as? WalletServiceError,
            WalletServiceError.remoteServiceError(message: Constants.anotherTransactionId)
        )
    }

    func test_sendTransaction_successIfTxIdMatches() async throws {
        // GIVEN
        let txData = try XCTUnwrap(Constants.transactionId.data(using: .utf8))
        await apiCoreMock.isolated { mock in
            mock.given(
                .sendRequestBasic(
                    origin: .any,
                    path: .any,
                    method: .any,
                    parameters: .any([String: String].self),
                    encoding: .any,
                    timeout: .any,
                    downloadProgress: .any,
                    willReturn: APIResponseModel(
                        result: .success(txData),
                        data: txData,
                        code: 200
                    )
                )
            )
        }

        // WHEN
        let result = await Result {
            try await self.sut.sendTransaction(BitcoinKit.Transaction.deserialize(Data(hex: Constants.transactionHex)!))
        }

        // THEN
        XCTAssertNil(result.error)
    }

    private func makeWallet(address: String = Constants.btcAddress) throws -> BtcWallet {
        let privateKeyData = "my long passphrase"
            .data(using: .utf8)!
            .sha256()
        let privateKey = PrivateKey(
            data: privateKeyData,
            network: .testnet,
            isPublicKeyCompressed: true
        )

        return try BtcWallet(
            unicId: "unicId",
            privateKey: privateKey,
            address: makeDefaultAddress(address: address)
        )
    }

    private func makeDefaultAddress(address: String = Constants.btcAddress) throws -> Address {
        try AddressConverterFactory()
            .make(network: .mainnetBTC)
            .convert(address: address)
    }

    private func assertAddressesEqual(_ lhs: Address, _ rhs: Address, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(lhs.lockingScript, rhs.lockingScript, file: file, line: line)
        XCTAssertEqual(lhs.stringValue, rhs.stringValue, file: file, line: line)
        XCTAssertEqual(lhs.lockingScriptPayload, rhs.lockingScriptPayload, file: file, line: line)
        XCTAssertEqual(lhs.scriptType, rhs.scriptType, file: file, line: line)
    }
}

private enum Constants {

    static let btcAddress = "1DU8Hi1sbHTpEP9vViBEkEw6noeUrgKkJH"

    static let anotherBtcAddress = "1JFHeK6mv8g7EmLj6g5MRgbQ58B9udtHC5"

    static let lockingScript = Data([118, 169, 20, 136, 194, 210, 250, 132, 98, 130, 200, 112, 167, 108, 173, 236, 190, 69, 196, 172, 215, 43, 182, 136, 172])

    static let lockingScript2 = Data([118, 169, 20, 189, 45, 218, 220, 109, 190, 133, 34, 44, 61, 83, 31, 41, 204, 37, 209, 62, 168, 11, 45, 136, 172])

    static let transactionId = "8b2654793f94539e5c66b87dee6d0908fb9728eb25c90396e25286c6d4b8a371"

    static let anotherTransactionId = String("8b2654793f94539e5c66b87dee6d0908fb9728eb25c90396e25286c6d4b8a371".reversed())

    static let transactionHex =
        "0100000001a0d73e3bd0aa2025d91eabd8512d5e19ad80752892f415480f75b97966b06f0e010000006a473044022072c8ecd3143e663520807c496dba3dc8010478f3cae09fcb65995be29737a55702206d23617cad2f88a3bd28757be956c731dbde06615fb9bb9fabf2d55e6a8f67ba0121037ec9f6126013088b3d1e8f844f3e755144756a4e9a7da6b0094c189f55031934ffffffff0228230000000000001976a914c6251d0e16c0e1946b745b69caa3a7c36014381088ac38560200000000001976a914931ef5cbdad28723ba9596de5da1145ae969a71888ac00000000"

    static let expectedTransaction = BitcoinKit.Transaction(
        version: 1,
        inputs: [
            TransactionInput(previousOutput: TransactionOutPoint(hash: Data(), index: 1), signatureScript: Data(), sequence: 4_294_967_295),
            TransactionInput(previousOutput: TransactionOutPoint(hash: Data(), index: 2), signatureScript: Data(), sequence: 4_294_967_295)
        ],
        outputs: [
            TransactionOutput(
                value: 10,
                lockingScript: Constants.lockingScript
            ),
            TransactionOutput(
                value: 19,
                lockingScript: Constants.lockingScript2
            )
        ],
        lockTime: 0
    )

    static let expectedUnspentTransactions = [
        UnspentTransaction(
            output: TransactionOutput(value: 10, lockingScript: Constants.lockingScript2),
            outpoint: TransactionOutPoint(hash: Data(), index: 1)
        ),
        UnspentTransaction(
            output: TransactionOutput(value: 20, lockingScript: Constants.lockingScript2),
            outpoint: TransactionOutPoint(hash: Data(), index: 2)
        )
    ]

    static let unspentTranscationsData = unspentTranscationsRawJSON.data(using: .utf8)!

    static let unspentTranscationsCorruptedData = Data(unspentTranscationsData.shuffled())

    static let unspentTranscationsRawJSON: String = """
        [
          {
            "txid": "1",
            "vout": 1,
            "value": 10,
            "status": {
                "confirmed": true
            }
          },
          {
            "txid": "1",
            "vout": 2,
            "value": 20,
            "status": {
                "confirmed": true
            }
          },
          {
            "txid": "1",
            "vout": 3,
            "value": 30,
            "status": {
                "confirmed": false
            }
          }
        ]
        """
}
