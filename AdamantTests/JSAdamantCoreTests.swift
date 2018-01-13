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
		
		guard let jsCore = Bundle.main.url(forResource: "adamant-core", withExtension: "js"),
			let jsUtilites = Bundle.main.url(forResource: "utilites", withExtension: "js") else {
				fatalError("Can't load system resources!")
		}
		
        core = try! JSAdamantCore(coreJsUrl: jsCore, utilitiesJsUrl: jsUtilites)
    }
	
    
    func testHashForPassphrase() {
        let passphrase = "process gospel angry height between flat always clock suit refuse shove verb"
		let hash = "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab"
		
		let freshHash = core.createHashFor(passphrase: passphrase)!
		XCTAssertEqual(hash, freshHash)
    }
	
	func testKeypairForPassphrase() {
		let passphrase = "process gospel angry height between flat always clock suit refuse shove verb"
		let publicKey = "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
		let privateKey =  "9001490b166816af75a15a3e2b0174bfe3be3dfaa63147b4f780ed3ab90ffeab8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f"
		
		let freshKeypair = core.createKeypairFor(passphrase: passphrase)!
		XCTAssertEqual(publicKey, freshKeypair.publicKey)
		XCTAssertEqual(privateKey, freshKeypair.privateKey)
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
