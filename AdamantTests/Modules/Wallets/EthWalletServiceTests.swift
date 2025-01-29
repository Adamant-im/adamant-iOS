//
//  EthWalletServiceTests.swift
//  Adamant
//
//  Created by Christian Benua on 15.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant
import CommonKit
import Web3Core
@testable import web3swift
import BigInt

final class EthWalletServiceTests: XCTestCase {
    private var sut: EthWalletService!

    private var apiCoreMock: APICoreProtocolMock!
    private var ethApiMock: EthApiServiceProtocolMock!
    private var walletStorage: EthWalletStorage!
    private var web3ProviderMock: Web3ProviderMock!
    private var increaseFeeServiceMock: IncreaseFeeServiceMock!
    private var keystoreManager: KeystoreManager!
    private var ethMock: IEthMock!
    private var web3: Web3!
    private var session: URLSession!
    
    override func setUp() async throws {
        try await super.setUp()
        apiCoreMock = APICoreProtocolMock()
        ethApiMock = EthApiServiceProtocolMock()
        web3ProviderMock = Web3ProviderMock()
        web3 = Web3(provider: web3ProviderMock)
        ethMock = IEthMock()
        web3.ethInstance = ethMock
        ethMock._provider = web3ProviderMock
        ethApiMock.api = EthApiCore(apiCore: apiCoreMock)
        ethApiMock.web3 = web3
        session = makeSession()
        web3ProviderMock.session = session
        let store = try XCTUnwrap(try makeKeystore())
        
        walletStorage = .init(keystore: store, unicId: "ERC20ETH")
        keystoreManager = .init([store])
        increaseFeeServiceMock = IncreaseFeeServiceMock()
        
        sut = EthWalletService()
        sut.increaseFeeService = increaseFeeServiceMock
        sut.setWalletForTests(walletStorage.getWallet())
        sut.ethApiService = ethApiMock
    }
    
    override func tearDown() {
        sut = nil
        apiCoreMock = nil
        ethApiMock = nil
        walletStorage = nil
        web3ProviderMock = nil
        increaseFeeServiceMock = nil
        web3 = nil
        keystoreManager = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func test_createTransaction_noWalletThrowsError() async throws {
        // given
        sut.setWalletForTests(nil)
        
        // when
        let result = await Result(catchingAsync: {
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
    
    func test_createTransaction_invalidAddressThrowsError() async throws {
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.invalidEthAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_createTransaction_invalidAmountThrowsError() async throws {
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.toEthAddress,
                amount: Decimal.nan,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .invalidAmount(.nan))
    }
    
    func test_createTransaction_noKeystoreManagerThrowsError() async throws {
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.toEthAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then
        switch result.error as? WalletServiceError {
        case .internalError?:
            break
        default:
            XCTFail("Expected `.internalError`, got :\(String(describing: result.error))")
        }
    }
    
    func test_createTransaction_correctFields() async throws {
        // given
        await setupKeyStoreManager()
        makeTransactionsCountMock()
        
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.toEthAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        // then
        XCTAssertNil(result.error)
        let transaction = try XCTUnwrap(result.value)
        XCTAssertEqual(transaction.from?.address, Constants.ethAddress)
        XCTAssertEqual(transaction.to.address, Constants.toEthAddress)
        XCTAssertEqual(transaction.nonce, BigUInt(exactly: Constants.nonce))
        XCTAssertEqual(transaction.gasPrice, BigUInt(clamping: 11).toWei())
        XCTAssertEqual(transaction.encode(), Constants.expectedTxData)
        XCTAssertEqual(transaction.hashForSignature(), Constants.extectedSignatureHash)
    }
    
    func test_createAndSendTransaction_sendsCorrectData() async throws {
        // given
        var didCallSendMock = false
        await setupKeyStoreManager()
        makeTransactionsCountMock()
        
        // when
        let result = await Result(catchingAsync: {
            try await self.sut.createTransaction(
                recipient: Constants.toEthAddress,
                amount: 10,
                fee: 0.1,
                comment: nil
            )
        })
        
        let transaction = try XCTUnwrap(result.value)
        let data = try XCTUnwrap(transaction.encode())
        let hash = data.toHexString().addHexPrefix()
        makeEthSendMock(expectedHash: hash) { didCallSendMock = true }
        
        let sendResult = await Result {
            try await self.sut.sendTransaction(transaction)
        }
        
        // then
        XCTAssertNil(sendResult.error)
        XCTAssertTrue(ethMock.invokedSendRaw)
        XCTAssertTrue(didCallSendMock)
    }
    
    private func setupKeyStoreManager() async {
        await ethApiMock.setKeystoreManager(keystoreManager)
        web3ProviderMock.attachedKeystoreManager = keystoreManager
    }
    
    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeTransactionsCountMock() {
        let prevHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = MockURLProtocol.combineHandlers(
            prevHandler
        ) { request in
            guard let stream = request.httpBodyStream else { return nil }

            let ethBody = try JSONDecoder().decode(EthRequestBody.self, from: Data(reading: stream))
            guard ethBody.method == Constants.transactionCountResponseMethod else { return nil }
            
            return try self.makeResponseAndMockData(
                url: request.url!,
                ethResponse: EthAPIResponse(result: "\(Constants.nonce)")
            )
        }
    }

    private func makeEthSendMock(expectedHash: String, _ onCall: @escaping () -> Void) {
        let prevHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = MockURLProtocol.combineHandlers(
            prevHandler
        ) { request in
            guard let stream = request.httpBodyStream else { return nil }

            let ethBody = try JSONDecoder().decode(EthRequestBody.self, from: Data(reading: stream))
            guard ethBody.method == Constants.sendTransactionResponseMethod else { return nil }

            XCTAssertEqual(ethBody.params[0] as? String, expectedHash)
            onCall()
            return try self.makeResponseAndMockData(
                url: request.url!,
                ethResponse: EthAPIResponse(result: expectedHash)
            )
        }
    }

    private func makeResponseAndMockData<T: Codable>(
        url: URL,
        ethResponse: EthAPIResponse<T>
    ) throws -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let mockData = try JSONEncoder().encode(ethResponse)
        return (response, mockData)
    }
    
    private func makeKeystore() throws -> BIP32Keystore? {
        try BIP32Keystore(
            mnemonics: "village lunch say patrol glow first hurt shiver name method dolphin sample",
            password: EthWalletService.walletPassword,
            mnemonicsPassword: "",
            language: .english,
            prefixPath: EthWalletService.walletPath
        )
    }
}

private enum Constants {
    static let transactionCountResponseMethod = "eth_getTransactionCount"
    static let sendTransactionResponseMethod = "eth_sendRawTransaction"

    static let extectedSignatureHash = Data([
        96, 116, 68, 167, 52, 14, 211, 94, 127, 63, 95, 104, 12, 204, 124,
        91, 13, 9, 179, 80, 252, 71, 102, 108, 115, 61, 254, 105, 0, 115, 81, 242
    ])
    static let expectedTxData = Data([
            248, 108, 2, 133, 2, 143, 166, 174, 0, 130, 94, 136, 148, 171, 253, 245,
            5, 255, 213, 88, 125, 158, 119, 7, 223, 180, 127, 69, 175, 31, 3, 226, 117,
            136, 138, 199, 35, 4, 137, 232, 0, 0, 128, 36, 160, 142, 188, 94, 138, 169,
            58, 131, 110, 28, 87, 29, 119, 40, 126, 98, 187, 13, 210, 2, 58, 244, 151, 234,
            149, 49, 14, 49, 195, 53, 129, 29, 40, 160, 79, 100, 92, 44, 207, 73, 57, 12, 184,
            108, 82, 24, 242, 197, 97, 151, 32, 107, 254, 152, 1, 73, 147, 254, 141, 113, 51,
            45, 211, 225, 3, 2
    ])

    static let nonce = 2

    static let ethAddress = "0xBA5CE20aE344CDBd6eAA01ffdDF1976d35Be142d"
    static let toEthAddress = "0xabfDF505fFd5587D9E7707dFB47F45AF1f03E275"
    static let invalidEthAddress = "0xBA5CE20aE344CDBd6eAA01ffdDF1976d35Be14"
}
