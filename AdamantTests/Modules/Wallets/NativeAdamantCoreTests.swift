//
//  NativeAdamantCoreTests.swift
//  Adamant
//
//  Created by Christian Benua on 30.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import XCTest
import CommonKit

final class NativeAdamantCoreTests: XCTestCase {
    func test_encodeMessage() throws {
        let (encryptedMessage, nonce) = try XCTUnwrap(NativeAdamantCore().encodeMessage(
            Constants.message,
            recipientPublicKey: Constants.publicKey,
            privateKey: Constants.privateKey
        ))
        
        let message = NativeAdamantCore().decodeMessage(
            rawMessage: encryptedMessage,
            rawNonce: nonce,
            senderPublicKey: Constants.publicKey,
            privateKey: Constants.privateKey
        )
        
        XCTAssertEqual(message, Constants.message)
    }
    
    func test_sign() {
        let signature = NativeAdamantCore().sign(
            transaction: Constants.transaction,
            senderId: Constants.senderPublicKey,
            keypair: Keypair(publicKey: Constants.senderPublicKey, privateKey: Constants.privateKey)
        )
        
        XCTAssertEqual(signature, Constants.expectedSignature)
    }
}

private enum Constants {
    static let privateKey = "c2b4df1562b93e5e37bef8551d430a21736da9b021cad8e3eec54cfca05b8db2fdfa0ad06afc6445c8d2c63078cba7f6d079ee0367e764cf286f42ab955a4d67"
    static let publicKey = "1ed651ec1c686c23249dadb2cb656edd5f8e7d35076815d8a81c395c3eed1a85"
    static let message = "Sample encode message for testing"
    
    static let expectedSignature = "328870db4ae22f0b74c829a32ae16ed3191d6dbfb13077f2ec0b35ee005270d13ff0f615de7d9a5486c4f7a66d41c99e814a7e7d2a8611d140476573266e2503"
    
    static let transaction = NormalizedTransaction(
        type: .chatMessage,
        amount: 0,
        senderPublicKey: Constants.senderPublicKey,
        requesterPublicKey: nil,
        date: Date(timeIntervalSince1970: 1738267672),
        recipientId: "U3716604363012166999",
        asset: TransactionAsset(
            chat: ChatAsset(
                message: "1507aaf7fdf4bdea3cf4e4df3d2476962be70102e2cac0961c25c1642713e2e14a0c8bf02e7f",
                ownMessage: "c488a53dff457feb4e46d83ae26c3821b9aa10d06a727eb5",
                type: .message
            )
        )
    )
    
    static let senderId = "U12686887375123482464"
    static let senderPublicKey = "fdfa0ad06afc6445c8d2c63078cba7f6d079ee0367e764cf286f42ab955a4d67"
}
