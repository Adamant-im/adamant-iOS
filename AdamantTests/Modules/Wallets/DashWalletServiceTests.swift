//
//  DashWalletServiceTests.swift
//  Adamant
//
//  Created by Christian Benua on 22.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import BitcoinKit
import CommonKit
import XCTest

final class DashWalletServiceTests: XCTestCase {
    
    private var sut: DashWalletService!
    private var lastTransactionStorageMock: DashLastTransactionStorageProtocolMock!
    private var apiServiceMock: DashApiServiceProtocolMock!
    private var apiCoreMock: APICoreProtocolMock!
    private var transactionFactoryMock: BitcoinKitTransactionFactoryProtocolMock!
    
    override func setUp() {
        super.setUp()
        
        lastTransactionStorageMock = DashLastTransactionStorageProtocolMock()
        transactionFactoryMock = BitcoinKitTransactionFactoryProtocolMock()
        transactionFactoryMock.stubbedTransactionFactory = {
            BitcoinKit.Transaction.createNewTransaction(
                toAddress: $0,
                amount: $1,
                fee: $2,
                changeAddress: $3,
                utxos: $4,
                lockTime: $5,
                keys: $6
            )
        }
        apiCoreMock = APICoreProtocolMock()
        apiServiceMock = DashApiServiceProtocolMock()
        apiServiceMock.api = DashApiCore(apiCore: apiCoreMock)
        sut = DashWalletService()
        
        sut.dashApiService = apiServiceMock
        sut.lastTransactionStorage = lastTransactionStorageMock
        sut.addressConverter = makeAddressConverter()
        sut.transactionFactory = transactionFactoryMock
    }
    
    override func tearDown() {
        sut = nil
        apiServiceMock = nil
        lastTransactionStorageMock = nil
        apiCoreMock = nil
        transactionFactoryMock = nil
        
        super.tearDown()
    }
    
    func test_createTransaction_throwsErrorWhenHasLastTransactionIdAndNotEnoughConfirmations() async throws {
        // given
        lastTransactionStorageMock.stubbedLastTransactionId = Constants.lastTransactionId
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicResult = APIResponseModel(
                result: .success(Constants.getTransactionZeroConfirmationsData),
                data: Constants.getTransactionZeroConfirmationsData,
                code: 200
            )
        }
        
        // when
        let result = await Result {
            try await self.sut.create(recipient: Constants.invalidDashAddress, amount: 10)
        }
        
        // then
        switch result.error as? WalletServiceError {
        case .remoteServiceError?:
            break
        default:
            XCTFail("Expected .remoteServiceError, but got \(result.error) error")
        }
    }
    
    func test_createTransaction_throwsErrorWhenNoWallet() async throws {
        // given
        lastTransactionStorageMock.stubbedLastTransactionId = nil
        
        // when
        let result = await Result {
            try await self.sut.create(recipient: Constants.invalidDashAddress, amount: 10)
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_createTransaction_throwsErrorWhenInvalidRecipient() async throws {
        // given
        sut.setWalletForTests(try makeWallet())
        lastTransactionStorageMock.stubbedLastTransactionId = nil
        
        // when
        let result = await Result {
            try await self.sut.create(recipient: Constants.invalidDashAddress, amount: 10)
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_createTransaction_badUnspentTransactionResponseDataThrowsError() async throws {
        // given
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsCorruptedData
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicGenericResult = APIResponseModel(result: .success(data), data: data, code: 200)
        }
        
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 30 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil)
        })
        
        // then
        XCTAssertNotNil(result.error)
    }
    
    func test_createTransaction_notEnoughMoneyThrowsError() async throws {
        // given
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicGenericResult = APIResponseModel(result: .success(data), data: data, code: 200)
        }
        
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 130 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil)
        })
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notEnoughMoney)
    }
    
    func test_createTransaction_enoughMoneyReturnsRealTransaction() async throws {
        // given
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicGenericResult = APIResponseModel(result: .success(data), data: data, code: 200)
        }
        
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 30 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil
            )
        })
        
        // then
        XCTAssertNil(result.error)
        XCTAssertEqual(result.value?.version, Constants.expectedTransaction.version)
        XCTAssertEqual(result.value?.outputs, Constants.expectedTransaction.outputs)
        XCTAssertEqual(
            transactionFactoryMock.invokedCreateTransactionParameters?.amount,
            30
        )
        XCTAssertEqual(
            transactionFactoryMock.invokedCreateTransactionParameters?.fee,
            1
        )
        XCTAssertEqual(
            transactionFactoryMock.invokedCreateTransactionParameters?.utxos,
            Constants.expectedUnspentTransactions
        )
        XCTAssertEqual(
            try XCTUnwrap(transactionFactoryMock.invokedCreateTransactionParameters?.toAddress).stringValue,
            Constants.validDashAddress
        )
        
        XCTAssertEqual(
            try XCTUnwrap(transactionFactoryMock.invokedCreateTransactionParameters?.changeAddress).stringValue,
            try makeWallet().address
        )
    }
    
    func test_createAndSendTransaction_updatesLastTransactionId() async throws {
        // given
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicGenericResult = APIResponseModel(result: .success(data), data: data, code: 200)
        }
        
        // when 1
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 30 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil
            )
        })
        
        // then 1
        XCTAssertNil(result.error)
        let transaction = try XCTUnwrap(result.value)
        
        // given 2
        await apiCoreMock.isolated { mock in
            mock.stubbedSendRequestBasicGenericResult = APIResponseModel(
                result: .success(Constants.sendTransactionResponseData),
                data: Constants.sendTransactionResponseData,
                code: 200
            )
        }
        
        // when 2
        let result2 = await Result(catchingAsync: {
            try await self.sut.sendTransaction(transaction)
        })
        
        // then 2
        XCTAssertNil(result2.error)
        XCTAssertEqual(lastTransactionStorageMock.invokedSetLastTransactionIdCount, 1)
        XCTAssertEqual(lastTransactionStorageMock.invokedSetLastTransactionIdParameters, transaction.txID)
    }
}

// MARK: Private

private extension DashWalletServiceTests {
    func makeWallet() throws -> DashWallet {
        let privateKeyData = Constants.passphrase.data(using: .utf8)!.sha256()
        let key = PrivateKey(data: privateKeyData, network: DashMainnet(), isPublicKeyCompressed: true)
        return try DashWallet(
            unicId: Constants.tokenUnicId,
            privateKey: key,
            addressConverter: makeAddressConverter()
        )
    }
    
    func makeAddressConverter() -> AddressConverter {
        AddressConverterFactory().make(network: DashMainnet())
    }
}

private enum Constants {
    
    static let tokenUnicId = "DASHDASH"
    
    static let validDashAddress = "Xp6kFbogHMD4QRBDLQdqRp5zUgzmfj1KPn"
    
    static let invalidDashAddress = "recipient"
    
    static let passphrase = "village lunch say patrol glow first hurt shiver name method dolphin dead"
    
    static let lastTransactionId = "lastTransactionId"
    
    static let getTransactionZeroConfirmationsData = getTransactionZeroConfirmationsJSON.data(using: .utf8)!
    
    // RPCResponseModel with BTCRawTransaction inside data
    static let getTransactionZeroConfirmationsJSON = """
{
    "id": "some id",
    "result": {
      "txid": "some txid",
      "confirmations": 0,
      "hash": "some hash",
      "valueIn": 1,
      "valueOut": 0.95,
      "vin": [],
      "vout": []
    }
}
"""
    
    static let unspentTranscationsData = unspentTranscationsRawJSON.data(using: .utf8)!
    
    static let unspentTranscationsCorruptedData = Data(unspentTranscationsData.shuffled())
    
    static let unspentTranscationsRawJSON: String = """
{
"result": [
  {
    "txid": "1",
    "script": "some script",
    "address": "some address",
    "outputIndex": 1,
    "satoshis": 30,
    "height": 1,
    "status": {
        "confirmed": true
    }
  },
  {
    "txid": "1",
    "script": "some script",
    "address": "some address",
    "outputIndex": 2,
    "satoshis": 20,
    "height": 1,
    "status": {
        "confirmed": true
    }
  }
]
}
"""
    
    static let sendTransactionResponseData = sendTransactionResponseRawJSON.data(using: .utf8)!
    
    static let sendTransactionResponseRawJSON: String = """
{
  "result": "txid"
}
"""
    
    static let expectedUnspentTransactions = [
        UnspentTransaction(
            output: TransactionOutput(value: 30, lockingScript: Constants.lockingScript2),
            outpoint: TransactionOutPoint(hash: Data(), index: 1)
        ),
        UnspentTransaction(
            output: TransactionOutput(value: 20, lockingScript: Constants.lockingScript2),
            outpoint: TransactionOutPoint(hash: Data(), index: 2)
        )
    ]
    
    static let expectedTransaction = BitcoinKit.Transaction(
        version: 1,
        inputs: [
            TransactionInput(previousOutput: TransactionOutPoint(hash: Data(), index: 1), signatureScript: Data(), sequence: 4294967295),
            TransactionInput(previousOutput: TransactionOutPoint(hash: Data(), index: 2), signatureScript: Data(), sequence: 4294967295)
        ],
        outputs: [
            TransactionOutput(
                value: 30,
                lockingScript: Constants.lockingScript
            ),
            TransactionOutput(
                value: 19,
                lockingScript: Constants.lockingScript2
            )
        ],
        lockTime: 0
    )
    
    static let lockingScript = Data([118, 169, 20, 147, 30, 245, 203, 218, 210, 135, 35, 186, 149, 150, 222, 93, 161, 20, 90, 233, 105, 167, 24, 136, 172])
    
    static let lockingScript2 = Data([118, 169, 20, 87, 246, 249, 0, 172, 122, 126, 60, 202, 183, 18, 50, 108, 215, 184, 86, 56, 252, 21, 168, 136, 172])
}
