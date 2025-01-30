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
    var transafersProvider: AdamantTransfersProvider!
    var accountService: AccountServiceMock!
    var accountsProviderMock: AccountsProviderMock!
    var admApiServiceMock: AdamantApiServiceProtocolMock!
    var chatProviderMock: ChatsProviderMock!
    var stack: InMemoryCoreDataStack!
    var adamantCoreMock: AdamantCoreMock!
    
    override func setUp() async throws {
        try await super.setUp()
        
        accountService = AccountServiceMock()
        accountsProviderMock = await AccountsProviderMock()
        admApiServiceMock = AdamantApiServiceProtocolMock()
        chatProviderMock = ChatsProviderMock()
        adamantCoreMock = AdamantCoreMock()
        stack = try InMemoryCoreDataStack(modelUrl: AdamantResources.coreDataModel)
        transafersProvider = AdamantTransfersProvider(
            apiService: admApiServiceMock,
            stack: stack,
            adamantCore: adamantCoreMock,
            accountService: accountService,
            accountsProvider: accountsProviderMock,
            securedStore: SecuredStoreMock(),
            transactionService: ChatTransactionServiceMock(),
            chatsProvider: chatProviderMock
        )
        sut = AdmWalletService()
        sut.transfersProvider = transafersProvider
    }
    
    override func tearDown() async throws {
        sut = nil
        transafersProvider = nil
        accountService = nil
        accountsProviderMock = nil
        admApiServiceMock = nil
        chatProviderMock = nil
        stack = nil
        adamantCoreMock = nil
        
        try await super.tearDown()
    }
    
    func test_sendMoney_isNotLoggedInThrowsError() async throws {
        // given
        accountService.account = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendMoney_noKeyPairThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendMoney_notEnoughMoneyThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: 20,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notEnoughMoney)
    }
    
    func test_sendMoney_invalidRecipientThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .failure(AccountsProviderError.notFound(address: ""))
        }
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendMoney_invalidRecipientPublicKeyThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(createCoreDataAccount())
        }
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendMoney_emptyRecipientChatroomThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(createCoreDataAccount(publicKey: "public key"))
        }
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendMoney_correctRecipientBadMessageEncodeThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(adamantCoreMock.invokedEncodeMessageCount, 1)
        XCTAssertEqual(adamantCoreMock.invokedEncodeMessageParameters?.message, Constants.comment)
        XCTAssertEqual(adamantCoreMock.invokedEncodeMessageParameters?.privateKey, accountService.keypair?.privateKey)
        XCTAssertEqual(adamantCoreMock.invokedEncodeMessageParameters?.recipientPublicKey, Constants.recipientPublicKeyAddress)
        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendMoney_signTransactionFailureThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = ("message", "nonce")
        adamantCoreMock.stubbedSignResult = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(adamantCoreMock.invokedSignCount, 1)
        let signParameters = try XCTUnwrap(adamantCoreMock.invokedSignParameters)
        XCTAssertEqual(signParameters.senderId, Constants.accountAddress)
        XCTAssertEqual(signParameters.keypair.publicKey, accountService.keypair?.publicKey)
        XCTAssertEqual(signParameters.keypair.privateKey, accountService.keypair?.privateKey)
        
        XCTAssertEqual(signParameters.transaction.type, .chatMessage)
        XCTAssertEqual(signParameters.transaction.amount, Constants.sendAmount)
        XCTAssertEqual(signParameters.transaction.recipientId, Constants.recipientAddress)
        
        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendMoney_sendTransactionFailureThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = ("message", "nonce")
        adamantCoreMock.stubbedSignResult = "signature"
        admApiServiceMock.stubbedSendMessageTransactionResult = .failure(.accountNotFound)
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionCount, 1)
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionParameters?.amount, Constants.sendAmount)
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionParameters?.recipientId, Constants.recipientAddress)
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionParameters?.senderId, Constants.accountAddress)
        
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
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = ("message", "nonce")
        adamantCoreMock.stubbedSignResult = "signature"
        admApiServiceMock.stubbedSendMessageTransactionResult = .success(1234)
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then        
        let transaction = try XCTUnwrap(result.value as? TransferTransaction)
        XCTAssertEqual(transaction.transactionId, "1234")
        XCTAssertEqual(transaction.statusEnum, .pending)
        XCTAssertEqual(transaction.chatRoom?.objectID, room.objectID)
    }
    
    // AdmWalletService have different logic for just sending money and sending money with comments
    
    func test_sendJustMoney_isNotLoggedInThrowsError() async throws {
        // given
        accountService.account = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendJustMoney_noKeyPairThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notLogged)
    }
    
    func test_sendJustMoney_notEnoughMoneyThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: 20,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .notEnoughMoney)
    }
    
    func test_sendJustMoney_invalidRecipientThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .failure(AccountsProviderError.invalidAddress(address: ""))
        }
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
    }
    
    func test_sendJustMoney_invalidRecipientQueriesDummyAndThrowsErrorWhenFails() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .failure(AccountsProviderError.notFound(address: ""))
            accountsProviderMock.stubbedGetDummyAccountResult = .failure(AccountsProviderDummyAccountError.invalidAddress(address: ""))
        }
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(result.error as? WalletServiceError, .accountNotFound)
        await MainActor.run {
            XCTAssertEqual(accountsProviderMock.invokedGetAccountCount, 1)
            XCTAssertEqual(accountsProviderMock.invokedGetDummyAccountCount, 1)
        }
    }
    
    func test_sendJustMoney_correctRecipientBadMessageEncodeThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(adamantCoreMock.invokedEncodeMessageCount, 0)
        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendJustMoney_signTransactionFailureThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = ("message", "nonce")
        adamantCoreMock.stubbedSignResult = nil
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: "",
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(adamantCoreMock.invokedSignCount, 1)
        let signParameters = try XCTUnwrap(adamantCoreMock.invokedSignParameters)
        XCTAssertEqual(signParameters.senderId, Constants.accountAddress)
        XCTAssertEqual(signParameters.keypair.publicKey, accountService.keypair?.publicKey)
        XCTAssertEqual(signParameters.keypair.privateKey, accountService.keypair?.privateKey)
        
        XCTAssertEqual(signParameters.transaction.type, .send)
        XCTAssertEqual(signParameters.transaction.amount, Constants.sendAmount)
        XCTAssertEqual(signParameters.transaction.recipientId, Constants.recipientAddress)
        
        switch result.error as? WalletServiceError {
        case .internalError:
            break
        default:
            XCTFail("Expected '.internalError', but got \(String(describing: result.error))")
        }
    }
    
    func test_sendJustMoney_sendTransactionFailureThrowsError() async throws {
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = ("message", "nonce")
        adamantCoreMock.stubbedSignResult = "signature"
        admApiServiceMock.stubbedSendMessageTransactionResult = .failure(.accountNotFound)
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionCount, 1)
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionParameters?.amount, Constants.sendAmount)
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionParameters?.recipientId, Constants.recipientAddress)
        XCTAssertEqual(admApiServiceMock.invokedSendMessageTransactionParameters?.senderId, Constants.accountAddress)
        
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
        // given
        accountService.account = makeAccount()
        accountService.keypair = makeKeypair(passphrase: Constants.passphrase)
        let (room, account) = setupCoreDataEntities(accountPublicKey: Constants.recipientPublicKeyAddress)
        await MainActor.run {
            accountsProviderMock.stubbedGetAccountResult = .success(account)
        }
        adamantCoreMock.stubbedEncodeMessageResult = ("message", "nonce")
        adamantCoreMock.stubbedSignResult = "signature"
        admApiServiceMock.stubbedSendMessageTransactionResult = .success(1234)
        
        // when
        let result = await Result {
            try await self.sut.sendMoney(
                recipient: Constants.recipientAddress,
                amount: Constants.sendAmount,
                comments: Constants.comment,
                replyToMessageId: nil
            )
        }
        
        // then
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
        NativeAdamantCore().createKeypairFor(passphrase: passphrase)
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
