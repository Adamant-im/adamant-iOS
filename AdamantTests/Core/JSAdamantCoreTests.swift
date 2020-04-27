//
//  JSAdamantCoreTests.swift
//  AdamantTests
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import XCTest
@testable import Adamant

class JSAdamantCoreTests: XCTestCase {
    var core: AdamantCore!
    
    override func setUp() {
        super.setUp()
        
        guard let jsCore = Bundle(for: type(of: self)).url(forResource: "adamant-core", withExtension: "js") else {
                fatalError("Can't load system resources!")
        }
        
        let core = JSAdamantCore()
        core.loadJs(from: jsCore, queue: DispatchQueue.global(qos: .utility)) { (result) in
            if case .error = result {
                fatalError()
            }
        }
        
        self.core = core
    }
    
    
    func testHashForPassphrase() {
        let passphrase = "process gospel angry height between flat always clock suit refuse shove verb"
        let hash = "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab"
        
        let freshHash = core.createHashFor(passphrase: passphrase)
        XCTAssertEqual(hash, freshHash)
    }
    
    func testKeypairForPassphrase() {
        let passphrase = "process gospel angry height between flat always clock suit refuse shove verb"
        let publicKey = "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
        let privateKey =  "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
        
        let freshKeypair = core.createKeypairFor(passphrase: passphrase)
        XCTAssertEqual(publicKey, freshKeypair?.publicKey)
        XCTAssertEqual(privateKey, freshKeypair?.privateKey)
    }
    
    func testGeneratePassphrase() {
        let passphrase = core.generateNewPassphrase()
        
        XCTAssert(passphrase.split(separator: " ").count == 12)
    }
    
    func testSignTransaction() {
        let transaction = NormalizedTransaction(type: TransactionType.send,
                                                amount: 60000000,
                                                senderPublicKey: "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
                                                requesterPublicKey: nil,
                                                timestamp: 13131802,
                                                recipientId: "U7038846184609740192",
                                                asset: TransactionAsset())
        let senderId = "U2279741505997340299"
        let keypair = Keypair(publicKey: "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
                              privateKey: "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
        
        let signature = "cdde6db8cfa9ebbca67f4625b0fdded5a130f01b4300423c4446e7b8ed79f95447be8b4dfd5d67b849d47bd9d834ddff3942499d350673e129f15ba2c1005807"
            
        let freshSignature = core.sign(transaction: transaction, senderId: senderId, keypair: keypair)
        XCTAssertEqual(signature, freshSignature)
    }
    
    func testEncodeMessage() {
        let message = "common"
        let aPublicKey = "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
        let aPrivateKey = "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
        let bPublicKey = "9f895a201fd92cc60ef02d2117d53f00dc2981903cb64b2f214777269b882209"
        let bPrivateKey = "e91ee8e6a23ac5ff9452a15a3fbd14098dc2c6a5abf6b12464b09eb033580b6d9f895a201fd92cc60ef02d2117d53f00dc2981903cb64b2f214777269b882209"
        
        guard let encoded = core.encodeMessage(message, recipientPublicKey: bPublicKey, privateKey: aPrivateKey) else {
            XCTFail()
            return
        }
        
        guard let decoded = core.decodeMessage(rawMessage: encoded.message, rawNonce: encoded.nonce, senderPublicKey: aPublicKey, privateKey: bPrivateKey) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(message, decoded)
    }
    
    func testDecodeMessage() {
        let publicKey = "9f895a201fd92cc60ef02d2117d53f00dc2981903cb64b2f214777269b882209"
        let privateKey = "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
        let message = "09af1ce7e5ed484ddca3c6d1410cbf4f793ea19210e7"
        let nonce = "31caaee2d35dcbd8b614e9d6bf6095393cb5baed259e7e37"
        let decodedMessage = "common"
        
        let freshMessage = core.decodeMessage(rawMessage: message, rawNonce: nonce, senderPublicKey: publicKey, privateKey: privateKey)
        
        XCTAssertEqual(freshMessage, decodedMessage)
    }
    
    
    // MARK: - Performance
    
    func testPerformanceHashForPassphrase() {
        let passphrase = "process gospel angry height between flat always clock suit refuse shove verb"
        
        self.measure {
            _ = core.createHashFor(passphrase: passphrase)
        }
    }
    
    func testPerformanceKeypairForPassphrase() {
        let passphrase = "process gospel angry height between flat always clock suit refuse shove verb"
        
        self.measure {
            _ = core.createKeypairFor(passphrase: passphrase)
        }
    }
    
    func testPerformanceSignTransaction() {
        let transaction = NormalizedTransaction(type: TransactionType.send,
                                                amount: 50000000,
                                                senderPublicKey: "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
                                                requesterPublicKey: nil,
                                                timestamp: 11325525,
                                                recipientId: "U48484848484848484848484",
                                                asset: TransactionAsset())
        let senderId = "U2279741505997340299"
        let keypair = Keypair(publicKey: "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
                              privateKey: "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
        
        self.measure {
            _ = core.sign(transaction: transaction, senderId: senderId, keypair: keypair)
        }
    }
}
