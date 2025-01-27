//
//  ERC20WalletServiceTests.swift
//  Adamant
//
//  Created by Christian Benua on 25.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

@testable import Adamant
import BigInt
@testable import CommonKit
import Web3Core
@testable import web3swift
import XCTest

final class ERC20WalletServiceTests: XCTestCase {
    private var sut: ERC20WalletService!
    private var erc20ApiMock: ERC20ApiServiceProtocolMock!
    private var apiCoreProtocolMock: APICoreProtocolMock!
    private var web3ProviderMock: Web3ProviderMock!
    private var increaseFeeServiceMock: IncreaseFeeServiceMock!
    private var ethMock: IEthMock!
    private var web3: Web3!
    private var session: URLSession!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let keystore = try XCTUnwrap(try BIP32Keystore(
            mnemonics: Constants.passphrase,
            password: EthWalletService.walletPassword,
            mnemonicsPassword: "",
            language: .english,
            prefixPath: EthWalletService.walletPath)
        )
        let ethAddress = try XCTUnwrap(keystore.addresses?.first)
        
        let eWallet = EthWallet(
            unicId: Constants.tokenUnicID,
            address: ethAddress.address,
            ethAddress: ethAddress,
            keystore: keystore
        )
        web3ProviderMock = Web3ProviderMock()
        web3 = Web3(provider: web3ProviderMock)
        ethMock = IEthMock()
        web3.ethInstance = ethMock
        ethMock._provider = web3ProviderMock
        apiCoreProtocolMock = APICoreProtocolMock()
        let ethApi = EthApiCore(apiCore: apiCoreProtocolMock)
        erc20ApiMock = ERC20ApiServiceProtocolMock()
        erc20ApiMock.api = ethApi
        erc20ApiMock.keystoreManager = .init([keystore])
        erc20ApiMock.contractAddress = try XCTUnwrap(EthereumAddress(from: Constants.token.contractAddress))
        erc20ApiMock.web3 = web3
        session = makeSession()
        web3ProviderMock.session = session
        increaseFeeServiceMock = IncreaseFeeServiceMock()

        sut = ERC20WalletService(token: Constants.token)
        sut.setWalletForTests(eWallet)
        sut.increaseFeeService = increaseFeeServiceMock
        sut.erc20ApiService = erc20ApiMock
    }
    
    override func tearDown() async throws {
        sut = nil
        erc20ApiMock = nil
        apiCoreProtocolMock = nil
        web3ProviderMock = nil
        ethMock = nil
        web3 = nil
        session = nil
        increaseFeeServiceMock = nil
        try await super.tearDown()
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
    
    func test_createTransaction_invalidRecipientAddressThrowsError() async throws {
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
    
    func test_createTransaction_noKeystoreThrowsError() async throws {
        // given
        erc20ApiMock.keystoreManager = nil
        
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
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_createTransaction_correctFields() async throws {
        // given
        makeTransactionsCountMock()
        var calledMakeDecimals = false
        makeDecimalsMock {
            calledMakeDecimals = true
        }
        
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
        XCTAssertTrue(calledMakeDecimals)
        XCTAssertNil(result.error)
        let transaction = try XCTUnwrap(result.value)
        XCTAssertEqual(transaction.from?.address, Constants.validEthAddress)
        XCTAssertEqual(transaction.to.address.lowercased(), Constants.token.contractAddress.lowercased())
        XCTAssertEqual(transaction.nonce, BigUInt(exactly: Constants.nonce))
        XCTAssertEqual(transaction.gasPrice, BigUInt(clamping: 11).toWei())
        XCTAssertEqual(transaction.hashForSignature(), Constants.expectedHashForSignature)
    }
    
    private func makeDecimalsMock(_ onCall: @escaping () -> Void) {
        let prevHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = MockURLProtocol.combineHandlers(
            prevHandler
        ) { request in
            guard let stream = request.httpBodyStream else { return nil }
            
            let ethBody = try JSONDecoder().decode(EthRequestBody.self, from: Data(reading: stream))
            guard ethBody.method == Constants.ethCallMethod else { return nil }
            onCall()
            XCTAssertEqual((ethBody.params[0] as? [String: Any])?["to"] as? String, Constants.token.contractAddress.lowercased())
            return try self.makeResponseAndMockData(
                url: request.url!,
                ethResponse: EthAPIResponse(result: Constants.decimalsMethodResponse)
            )
        }
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
    
    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private enum Constants {
    
    static let passphrase = "village lunch say patrol glow first hurt shiver name method dolphin sample"
    
    static let tokenUnicID = "ERC20\(token.symbol)\(token.contractAddress)"
    
    static let token = ERC20Token(
        symbol: "BNB",
        name: "Binance Coin",
        contractAddress: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52",
        decimals: 18,
        naturalUnits: 18,
        defaultVisibility: false,
        defaultOrdinalLevel: nil,
        reliabilityGasPricePercent: 10,
        reliabilityGasLimitPercent: 10,
        defaultGasPriceGwei: 10,
        defaultGasLimit: 58000,
        warningGasPriceGwei: 25,
        transferDecimals: 6
    )
    
    static let toEthAddress = "0xabfDF505fFd5587D9E7707dFB47F45AF1f03E275"
    static let invalidEthAddress = "0xBA5CE20aE344CDBd6eAA01ffdDF1976d35Be14"
    static let validEthAddress = "0xBA5CE20aE344CDBd6eAA01ffdDF1976d35Be142d"
    
    static let transactionCountResponseMethod = "eth_getTransactionCount"
    static let decimalsMethod = "decimals"
    static let ethCallMethod = "eth_call"
    static let nonce = 2
    static let decimalsMethodResponse = "0x0000000000000000000000000000000000000000000000000000000000000006"
    
    static let expectedHashForSignature = Data([
        19, 32, 58, 56, 131, 178, 156, 49, 149,
        112, 90, 80, 243, 4, 152, 101, 158, 186,
        191, 16, 58, 253, 186, 73, 77, 9, 179,
        26, 213, 185, 77, 201
    ])
}
