//
//  AdmWalletServiceTests.swift
//  Adamant
//
//  Created by Christian Benua on 28.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant
import CommonKit

final class AdmWalletServiceTests: XCTestCase {
    
    var sut: AdmWalletService!
    var transfersProvider: AdamantTransfersProvider!
    var accountServiceMock: AccountServiceMock!
    var accountsProviderMock: AccountsProviderMock!
    var admApiServiceMock: AdamantApiServiceProtocolMock!
    var chatProviderMock: ChatsProviderMock!
    var stack: InMemoryCoreDataStack!
    var adamantCoreMock: AdamantCoreMock!
    
    override func setUp() async throws {
        try await super.setUp()
        
        accountServiceMock = AccountServiceMock()
        accountsProviderMock = await AccountsProviderMock()
        admApiServiceMock = AdamantApiServiceProtocolMock()
        chatProviderMock = ChatsProviderMock()
        adamantCoreMock = AdamantCoreMock()
        stack = try InMemoryCoreDataStack(modelUrl: AdamantResources.coreDataModel)
        transfersProvider = AdamantTransfersProvider(
            apiService: admApiServiceMock,
            stack: stack,
            adamantCore: adamantCoreMock,
            accountService: accountServiceMock,
            accountsProvider: accountsProviderMock,
            securedStore: SecuredStoreMock(),
            transactionService: ChatTransactionServiceMock(),
            chatsProvider: chatProviderMock
        )
        sut = AdmWalletService()
        sut.transfersProvider = transfersProvider
    }
    
    override func tearDown() async throws {
        sut = nil
        transfersProvider = nil
        accountServiceMock = nil
        accountsProviderMock = nil
        admApiServiceMock = nil
        chatProviderMock = nil
        stack = nil
        adamantCoreMock = nil
        
        try await super.tearDown()
    }
    
    func test_sendMoney_isNotLoggedInThrowsError() async throws {
        // GIVEN
        accountServiceMock.given(.account(getter: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendMoney_noKeyPairThrowsError() async throws {
        // GIVEN
        accountServiceMock.given(.account(getter: makeAccount()))
        accountServiceMock.given(.keypair(getter: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendMoney_notEnoughMoneyThrowsError() async throws {
        // GIVEN
        setupAccountService()
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: 20,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notEnoughMoney)
    }
    
    func test_sendMoney_invalidRecipientThrowsError() async throws {
        // GIVEN
        setupAccountService()
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willThrow: AccountsProviderError.notFound(address: "")))
        }
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendMoney_invalidRecipientPublicKeyThrowsError() async throws {
        // GIVEN
        setupAccountService()
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: createCoreDataAccount()))
        }
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendMoney_emptyRecipientChatroomThrowsError() async throws {
        // GIVEN
        setupAccountService()
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: createCoreDataAccount(publicKey: "public key")))
        }
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendMoney_correctRecipientBadMessageEncodeThrowsError() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        let privateKey = try XCTUnwrap(accountServiceMock.keypair)
        adamantCoreMock.verify(
            .encodeMessage(
                .value(Constants.comment),
                recipientPublicKey: .value(Constants.recipientPublicKeyAddress),
                privateKey: .value(privateKey.privateKey)
            ),
            count: 1
        )
        
        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendMoney_signTransactionFailureThrowsError() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: ("message", "nonce")))
        adamantCoreMock.given(.sign(transaction: .any, senderId: .any, keypair: .any, willReturn: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        let keyPair = try XCTUnwrap(accountServiceMock.keypair)
        adamantCoreMock.verify(.sign(
            transaction: .matching {
                $0.type == .chatMessage
                && $0.amount == Constants.sendAmount
                && $0.recipientId == Constants.recipientAddress
            },
            senderId: .value(Constants.accountAddress),
            keypair: .value(keyPair)),
                               count: 1
        )
        
        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendMoney_sendTransactionFailureThrowsError() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.sign(transaction: .any, senderId: .any, keypair: .any, willReturn: "signature"))
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: ("message", "nonce")))
        admApiServiceMock.given(.sendMessageTransaction(transaction: .any, willReturn: .failure(.accountNotFound)))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        
        admApiServiceMock.verify(.sendMessageTransaction(
            transaction: .matching {
                $0.type == .chatMessage
                && $0.senderPublicKey == "8eefafa8d2f6a51bde207bcdc9029f3725f5d6aaa8f9b8fe3cd6d65d1f315a54"
                && $0.senderId == Constants.accountAddress
                && $0.recipientId == Constants.recipientAddress
                && $0.amount == Constants.sendAmount
                && $0.signature == "signature"
            }
        ), count: 1)
        
        let transactions: [TransferTransaction] = try stack.container.viewContext.fetch(TransferTransaction.fetchRequest())
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.statusEnum, .failed)
                
        switch result.error as? WalletServiceError {
        case .remoteServiceError:
            break
        default:
            XCTFail("Expected '.remoteServiceError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendMoney_sendTransactionSuccess() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.sign(transaction: .any, senderId: .any, keypair: .any, willReturn: "signature"))
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: ("message", "nonce")))
        admApiServiceMock.given(.sendMessageTransaction(transaction: .any, willReturn: .success(1234)))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN        
        let transaction = try XCTUnwrap(result.value as? TransferTransaction)
        XCTAssertEqual(transaction.transactionId, "1234")
        XCTAssertEqual(transaction.statusEnum, .pending)
        XCTAssertEqual(transaction.chatRoom?.objectID, room.objectID)
    }
    
    // AdmWalletService have different logic for just sending money and sending money with comments
    
    func test_sendJustMoney_isNotLoggedInThrowsError() async throws {
        // GIVEN
        accountServiceMock.given(.account(getter: makeAccount()))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendJustMoney_noKeyPairThrowsError() async throws {
        // GIVEN
        accountServiceMock.given(.account(getter: makeAccount()))
        accountServiceMock.given(.keypair(getter: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendJustMoney_notEnoughMoneyThrowsError() async throws {
        // GIVEN
        setupAccountService()
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: 20,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .notEnoughMoney)
    }
    
    func test_sendJustMoney_invalidRecipientThrowsError() async throws {
        // GIVEN
        setupAccountService()
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willThrow: AccountsProviderError.invalidAddress(address: "")))
        }
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendJustMoney_invalidRecipientQueriesDummyAndThrowsErrorWhenFails() async throws {
        // GIVEN
        setupAccountService()
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willThrow: AccountsProviderError.notFound(address: "")))
            accountsProviderMock.given(.getDummyAccount(for: .any, willThrow: AccountsProviderDummyAccountError.invalidAddress(address: "")))
        }
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // THEN
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
        await MainActor.run {
            accountsProviderMock.verify(.getAccount(byAddress: .any), count: 1)
            accountsProviderMock.verify(.getDummyAccount(for: .any), count: 1)
        }
    }
    
    func test_sendJustMoney_correctRecipientBadMessageEncodeThrowsError() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: nil))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // THEN
        adamantCoreMock.verify(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any), count: 0)
        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendJustMoney_signTransactionFailureThrowsError() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.sign(transaction: .any, senderId: .any, keypair: .any, willReturn: nil))
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: ("message", "nonce")))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // THEN
        let keyPair = try XCTUnwrap(accountServiceMock.keypair)
        adamantCoreMock.verify(.sign(
            transaction: .matching {
                $0.type == .send
                && $0.amount == Constants.sendAmount
                && $0.recipientId == Constants.recipientAddress
            },
            senderId: .value(Constants.accountAddress),
            keypair: .value(keyPair)),
                               count: 1
        )

        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendJustMoney_sendTransactionFailureThrowsError() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.sign(transaction: .any, senderId: .any, keypair: .any, willReturn: "signature"))
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: ("message", "nonce")))
        admApiServiceMock.given(.sendMessageTransaction(transaction: .any, willReturn: .failure(.accountNotFound)))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        admApiServiceMock.verify(.sendMessageTransaction(
            transaction: .matching {
                $0.type == .chatMessage
                && $0.senderPublicKey == "8eefafa8d2f6a51bde207bcdc9029f3725f5d6aaa8f9b8fe3cd6d65d1f315a54"
                && $0.senderId == Constants.accountAddress
                && $0.recipientId == Constants.recipientAddress
                && $0.amount == Constants.sendAmount
                && $0.signature == "signature"
            }
        ), count: 1)
        
        let transactions: [TransferTransaction] = try stack.container.viewContext.fetch(TransferTransaction.fetchRequest())
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.statusEnum, .failed)
        
        switch result.error as? WalletServiceError {
        case .remoteServiceError:
            break
        default:
            XCTFail("Expected '.remoteServiceError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendJustMoney_sendTransactionSuccess() async throws {
        // GIVEN
        setupAccountService()
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.given(.getAccount(byAddress: .any, willReturn: account))
        }
        adamantCoreMock.given(.sign(transaction: .any, senderId: .any, keypair: .any, willReturn: "signature"))
        adamantCoreMock.given(.encodeMessage(.any, recipientPublicKey: .any, privateKey: .any, willReturn: ("message", "nonce")))
        admApiServiceMock.given(.sendMessageTransaction(transaction: .any, willReturn: .success(1234)))
        
        // WHEN
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // THEN
        let transaction = try XCTUnwrap(result.value as? TransferTransaction)
        XCTAssertEqual(transaction.transactionId, "1234")
        XCTAssertEqual(transaction.statusEnum, .pending)
        XCTAssertEqual(transaction.chatRoom?.objectID, room.objectID)
    }
}

private extension AdmWalletServiceTests {
    func makeAccount() -> AdamantAccount {
        return AdamantAccount(
            address: Constants.accountAddress,
            unconfirmedBalance: Constants.unconfirmedBalance,
            balance: Constants.balance,
            publicKey: nil,
            unconfirmedSignature: 0,
            secondSignature: 0,
            secondPublicKey: nil,
            multisignatures: nil,
            uMultisignatures: nil,
            isDummy: false
        )
    }
    
    func setupAccountService() {
        accountServiceMock.given(.account(getter: makeAccount()))
        accountServiceMock.given(.keypair(getter: makeKeypair(passphrase: Constants.passphrase)))
    }
    
    func setupCoreDataEntities(accountPublicKey: String? = nil) -> (Chatroom, CoreDataAccount) {
        let account = createCoreDataAccount(publicKey: accountPublicKey)
        let room = createChatroom()
        account.chatroom = room
        
        return (room, account)
    }
    
    func createCoreDataAccount(publicKey: String? = nil) -> CoreDataAccount {
        let account = CoreDataAccount(context: stack.container.viewContext)
        
        account.address = Constants.recipientAddress
        account.publicKey = publicKey
        
        return account
    }
    
    func createChatroom() -> Chatroom {
        let room = Chatroom(context: stack.container.viewContext)
        
        return room
    }
    
    func makeKeypair(passphrase: String) -> Keypair? {
        NativeAdamantCore().createKeypairFor(passphrase: passphrase, password: "")
    }
}

private enum Constants {
    static let passphrase = "village lunch say patrol glow first hurt shiver name method dolphin dead"
    
    static let accountAddress = "adamant address"
    static let recipientAddress = "recipient address"
    static let recipientPublicKeyAddress = "public key"
    static let unconfirmedBalance: Decimal = 10
    static let balance: Decimal = 8
    static let sendAmount: Decimal = 5
    
    static let comment = "comment"
}
