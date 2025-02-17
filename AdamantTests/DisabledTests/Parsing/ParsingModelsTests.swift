//
//  ParsingModelsTests.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 13.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class ParsingModelsTests: XCTestCase {
    func testTransactionSend() {
        let t: Transaction = TestTools.LoadJsonAndDecode(filename: "TransactionSend")
        
        XCTAssertEqual(t.id, 1873173140086400619)
        XCTAssertEqual(t.height, 777336)
        XCTAssertEqual(t.blockId, "10172499053153614044")
        XCTAssertEqual(t.type, TransactionType.send)
        XCTAssertEqual(t.timestamp, 10724447)
        XCTAssertEqual(t.senderPublicKey, "cdab95b082b9774bd975677c868261618c7ce7bea97d02e0f56d483e30c077b6")
        XCTAssertNil(t.requesterPublicKey)
        XCTAssertEqual(t.senderId, "U15423595369615486571")
        XCTAssertEqual(t.recipientId, "U2279741505997340299")
        XCTAssertEqual(t.recipientPublicKey, "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
        XCTAssertEqual(t.amount, Decimal(0.49))
        XCTAssertEqual(t.fee, Decimal(0.5))
        XCTAssertEqual(t.signature, "539f80c8a71abc8d4d31e5bd0d0ddb1ea98499c1d43fe5ab07faec8d376cd12357cf17bca36dc7a561085cbd615e64c523f2b17807d3f4da787baaa657aa450a")
        XCTAssertNil(t.signSignature)
        XCTAssert(t.signatures.count == 0)
        XCTAssertEqual(t.confirmations, 148388)
        XCTAssertNil(t.asset.chat)
    }

    func testTransactionChat() {
        let t: Transaction = TestTools.LoadJsonAndDecode(filename: "TransactionChat")

        XCTAssertEqual(t.id, 16214962152767034408)
        XCTAssertEqual(t.height, 857385)
        XCTAssertEqual(t.blockId, "11054360802486546958")
        XCTAssertEqual(t.type, TransactionType.chatMessage)
        XCTAssertEqual(t.timestamp, 11138999)
        XCTAssertEqual(t.senderPublicKey, "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
        XCTAssertNil(t.requesterPublicKey)
        XCTAssertEqual(t.senderId, "U2279741505997340299")
        XCTAssertEqual(t.recipientId, "U15423595369615486571")
        XCTAssertNil(t.recipientPublicKey)
        XCTAssertEqual(t.amount, 0)
        XCTAssertEqual(t.fee, Decimal(0.005))
        XCTAssertEqual(t.signature, "7c58921d29beb5fbc7886053d81b37d8495db53848ebe04a8847f06dbcb810d8d675ea6501b1fe9b5ce7fbf9d7660a09895ac915dc82e6e8878fd0e919538c0e")
        XCTAssertNil(t.signSignature)
        XCTAssert(t.signatures.count == 0)
        XCTAssertEqual(t.confirmations, 0)
        XCTAssertEqual(t.asset.chat!.message, "e2d7cde88920914cd58f2ab86bca799052d385fe92976b41b59c4267")
        XCTAssertEqual(t.asset.chat!.ownMessage, "898e0bd7d8008fb0396195a911d19a24a7234d2e2a00cdf9")
        XCTAssertEqual(t.asset.chat!.type, ChatType.message)
    }
    
    func testEncodingTransactionChat() {
        let t: Transaction = TestTools.LoadJsonAndDecode(filename: "TransactionChat")
        
        let rawTransaction = try! JSONEncoder().encode(t)
        
        let newT = try! JSONDecoder().decode(Transaction.self, from: rawTransaction)
        
        XCTAssertEqual(t.id, newT.id)
        XCTAssertEqual(t.height, newT.height)
        XCTAssertEqual(t.blockId, newT.blockId)
        XCTAssertEqual(t.type, newT.type)
        XCTAssertEqual(t.timestamp, newT.timestamp)
        XCTAssertEqual(t.senderPublicKey, newT.senderPublicKey)
        XCTAssertEqual(t.senderId, newT.senderId)
        XCTAssertEqual(t.recipientId, newT.recipientId)
        XCTAssertEqual(t.amount, newT.amount)
        XCTAssertEqual(t.fee, newT.fee)
        XCTAssertEqual(t.signature, newT.signature)
        XCTAssertEqual(t.confirmations, newT.confirmations)
        XCTAssertEqual(t.asset.chat!.message, newT.asset.chat!.message)
        XCTAssertEqual(t.asset.chat!.ownMessage, newT.asset.chat!.ownMessage)
        XCTAssertEqual(t.asset.chat!.type, newT.asset.chat!.type)

        XCTAssertNil(newT.requesterPublicKey)
        XCTAssertNil(newT.recipientPublicKey)
        XCTAssertNil(newT.signSignature)
        XCTAssert(newT.signatures.count == 0)
    }

    func testAccount() {
        let t: AdamantAccount = TestTools.LoadJsonAndDecode(filename: "Account")

        XCTAssertEqual(t.address, "U2279741505997340299")
        XCTAssertEqual(t.unconfirmedBalance, Decimal(0.345))
        XCTAssertEqual(t.balance, Decimal(0.345))
        XCTAssertEqual(t.publicKey, "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
        XCTAssertEqual(t.unconfirmedSignature, 0)
        XCTAssertEqual(t.secondSignature, 0)
        XCTAssertNil(t.secondPublicKey)
        XCTAssert(t.multisignatures == nil || t.multisignatures!.count == 0)
        XCTAssert(t.uMultisignatures == nil || t.uMultisignatures!.count == 0)
    }

    func testChat() {
        let c: ChatAsset = TestTools.LoadJsonAndDecode(filename: "Chat")

        XCTAssertEqual(c.message, "7b7b3802f1d081e10624a373628fd0ba57e9348a7bca196c7511b05403a10611e3b4cf8b37cb9858f7f52cd5")
        XCTAssertEqual(c.ownMessage, "f4f7972f735997b4c2014d87cb491bb156f9cc4d0404cb9c")
        XCTAssertEqual(c.type, ChatType.message)
    }

    func testNormalizedTransaction() {
        let t: NormalizedTransaction = TestTools.LoadJsonAndDecode(filename: "NormalizedTransaction")
        
        XCTAssertEqual(t.type, TransactionType.send)
        XCTAssertEqual(t.amount, Decimal(505.05050505))
        XCTAssertEqual(t.senderPublicKey, "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
        XCTAssertNil(t.requesterPublicKey)
        XCTAssertEqual(t.timestamp, 11236791)
        XCTAssertNil(t.asset.chat)
        XCTAssertEqual(t.recipientId, "U2279741505997340299")
    }
}
