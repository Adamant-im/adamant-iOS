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
        // GIVEN
        lastTransactionStorageMock.given(.getLastTransactionId(willReturn: Constants.lastTransactionId))
        await apiCoreMock.isolated { mock in
            mock.given(.sendRequestBasic(origin: .any, path: .any, method: .any, jsonParameters: .any, timeout: .any, willReturn: APIResponseModel(
                result: .success(Constants.getTransactionZeroConfirmationsData),
                data: Constants.getTransactionZeroConfirmationsData,
                code: 200
            )))
        }
        
        // WHEN
        let result = await Result {
            try await self.sut.create(recipient: Constants.invalidDashAddress, amount: 10)
        }
        
        // THEN
        switch result.error as? WalletServiceError {
        case .remoteServiceError?:
            break
        default:
            XCTFail("Expected .remoteServiceError, but got \(result.error) error")
        }
    }
    
    func test_createTransaction_throwsErrorWhenNoWallet() async throws {
        // GIVEN
        lastTransactionStorageMock.given(.getLastTransactionId(willReturn: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.create(recipient: Constants.invalidDashAddress, amount: 10)
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_createTransaction_throwsErrorWhenInvalidRecipient() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        lastTransactionStorageMock.given(.getLastTransactionId(willReturn: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.create(recipient: Constants.invalidDashAddress, amount: 10)
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_createTransaction_badUnspentTransactionResponseDataThrowsError() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTransactionsCorruptedData
        await apiCoreMock.isolated { mock in
            mock.given(.sendRequestBasic(origin: .any, path: .any, method: .any, parameters: .any(DashGetUnspentTransactionDTO.self), encoding: .any, timeout: .any, downloadProgress: .any, willReturn: APIResponseModel(
                result: .success(data),
                data: data,
                code: 200
            )))
        }
        
        // WHEN
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 30 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil)
        })
        
        // THEN
        XCTAssertNotNil(result.error)
    }
    
    func test_createTransaction_notEnoughMoneyThrowsError() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.given(.sendRequestBasic(origin: .any, path: .any, method: .any, parameters: .any(DashGetUnspentTransactionDTO.self), encoding: .any, timeout: .any, downloadProgress: .any, willReturn: APIResponseModel(
                result: .success(data),
                data: data,
                code: 200
            )))
        }
        
        // WHEN
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 130 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil)
        })
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notEnoughMoney)
    }
    
    func test_createTransaction_enoughMoneyReturnsRealTransaction() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.given(.sendRequestBasic(origin: .any, path: .any, method: .any, parameters: .any(DashGetUnspentTransactionDTO.self), encoding: .any, timeout: .any, downloadProgress: .any, willReturn: APIResponseModel(
                result: .success(data),
                data: data,
                code: 200
            )))
        }
        transactionFactoryMock.given(.createTransaction(toAddress: .any, amount: .any, fee: .any, changeAddress: .any, utxos: .any, lockTime: .any, keys: .any, willReturn: Constants.expectedTransaction))
        
        // WHEN
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 30 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil
            )
        })
        
        // THEN
        XCTAssertNil(result.error)
        XCTAssertEqual(result.value?.version, Constants.expectedTransaction.version)
        XCTAssertEqual(result.value?.outputs, Constants.expectedTransaction.outputs)
        let changeAddress = try XCTUnwrap(try makeWallet().address)
        transactionFactoryMock.verify(.createTransaction(
            toAddress: .matching { $0.stringValue == Constants.validDashAddress },
            amount: .value(30),
            fee: .value(1),
            changeAddress: .matching { $0.stringValue == changeAddress },
            utxos: .value(Constants.expectedUnspentTransactions),
            lockTime: .any,
            keys: .any
        ))
    }
    
    func test_createAndSendTransaction_updatesLastTransactionId() async throws {
        // GIVEN
        sut.setWalletForTests(try makeWallet())
        let data = Constants.unspentTranscationsData
        await apiCoreMock.isolated { mock in
            mock.given(.sendRequestBasic(origin: .any, path: .any, method: .any, parameters: .any(DashGetUnspentTransactionDTO.self), encoding: .any, timeout: .any, downloadProgress: .any, willReturn: APIResponseModel(
                result: .success(data),
                data: data,
                code: 200
            )))
        }

        transactionFactoryMock.given(.createTransaction(toAddress: .any, amount: .any, fee: .any, changeAddress: .any, utxos: .any, lockTime: .any, keys: .any, willReturn: Constants.expectedTransaction))
        
        // WHEN 1
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.validDashAddress,
                amount: 30 / DashWalletService.multiplier,
                fee: 1 / DashWalletService.multiplier,
                comment: nil
            )
        })
        
        // THEN 1
        XCTAssertNil(result.error)
        let transaction = try XCTUnwrap(result.value)
        
        // GIVEN 2
        await apiCoreMock.isolated { mock in
            mock.given(.sendRequestBasic(origin: .any, path: .any, method: .any, parameters: .any(DashSendRawTransactionDTO.self), encoding: .any, timeout: .any, downloadProgress: .any, willReturn: APIResponseModel(
                result: .success(Constants.sendTransactionResponseData),
                data: Constants.sendTransactionResponseData,
                code: 200
            )))
        }
        
        // WHEN 2
        let result2 = await Result(catchingAsync: {
            try await self.sut.sendTransaction(transaction)
        })
        
        // THEN 2
        XCTAssertNil(result2.error)
        lastTransactionStorageMock.verify(.setLastTransactionId(.value(transaction.txID)), count: 1)
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
    
    // RPCResponseModel with BTCRawTransaction inside data
    static let getTransactionZeroConfirmationsData = Data.readResource(
        name: "dash_unverified_unspent_transactions",
        withExtension: "json"
    )!
    
    static let unspentTranscationsData = Data.readResource(
        name: "dash_unspent_transaction_unit_test",
        withExtension: "json"
    )!
    
    static let unspentTransactionsCorruptedData = Data()
    
    static let sendTransactionResponseData = Data.readResource(
        name: "dash_send_transaction_unit_response",
        withExtension: "json"
    )!
    
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
