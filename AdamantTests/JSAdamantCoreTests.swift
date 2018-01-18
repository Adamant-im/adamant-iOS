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
		
		guard let jsCore = Bundle.main.url(forResource: "adamant-core", withExtension: "js") else {
				fatalError("Can't load system resources!")
		}
		
        core = try! JSAdamantCore(coreJsUrl: jsCore)
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
	
	func testSignTransaction() {
		let transaction = NormalizedTransaction(type: TransactionType.send,
												amount: 50000000,
												senderPublicKey: "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
												requesterPublicKey: nil,
												timestamp: 11325525,
												recipientId: "U48484848484848484848484",
												asset: TransactionAsset(chat: nil))
		let senderId = "U2279741505997340299"
		let keypair = Keypair(publicKey: "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
							  privateKey: "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
		
		let signature = "cf2718a77527016ae1a847c190b0986e75fdc57926afc5aaebfa16fb7cb2cb64690b79cab9230f3328695770cf36370cc5be2b323419873081aa351d32b5db05"
			
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
		
		guard let decoded = core.decodeMessage(rawMessage: encoded.message, rawNonce: encoded.ownMessage, senderPublicKey: aPublicKey, privateKey: bPrivateKey) else {
			XCTFail()
			return
		}
		
		XCTAssertEqual(message, decoded)
	}
	
	func testDecodeMessage() {
		let publicKey = "9f895a201fd92cc60ef02d2117d53f00dc2981903cb64b2f214777269b882209"
		let privateKey = "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
		let message = "09af1ce7e5ed484ddca3c6d1410cbf4f793ea19210e7"
		let ownMessage = "31caaee2d35dcbd8b614e9d6bf6095393cb5baed259e7e37"
		let decodedMessage = "common"
		
		let freshMessage = core.decodeMessage(rawMessage: message, rawNonce: ownMessage, senderPublicKey: publicKey, privateKey: privateKey)
		
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
												asset: TransactionAsset(chat: nil))
		let senderId = "U2279741505997340299"
		let keypair = Keypair(publicKey: "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
							  privateKey: "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f")
		
		self.measure {
			_ = core.sign(transaction: transaction, senderId: senderId, keypair: keypair)
		}
	}
}
