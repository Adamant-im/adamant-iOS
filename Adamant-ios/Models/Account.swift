//
//  Account.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 06.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import Foundation

struct Account {
	let address: String
	var unconfirmedBalance: Int64
	var balance: Int64
	let publicKey: AdamantHash
	let unconfirmedSignature: Int
	let secondSignature: Int
	let secondPublicKey: AdamantHash?
}

extension Account: Decodable {
	enum CodingKeys: String, CodingKey {
		case address
		case unconfirmedBalance
		case balance
		case publicKey
		case unconfirmedSignature
		case secondSignature
		case secondPublicKey
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.address = try container.decode(String.self, forKey: .address)
		self.unconfirmedBalance = Int64(try container.decode(String.self, forKey: .unconfirmedBalance))!
		self.balance = Int64(try container.decode(String.self, forKey: .balance))!
		self.unconfirmedSignature = try container.decode(Int.self, forKey: .unconfirmedSignature)
		
		let publicKey = try container.decode(String.self, forKey: .publicKey)
		self.publicKey = AdamantHash(hex: publicKey)
		
		self.secondSignature = 0
		self.secondPublicKey = nil
//		self.secondSignature = try container.decode(Int.self, forKey: .secondSignature)
//		self.secondPublicKey = try? container.decode(String.self, forKey: .secondPublicKey)
	}
}

// MARK: - JSON
/*
{
	"address": "U2279741505997340299",
	"unconfirmedBalance": "49000000",
	"balance": "49000000",
	"publicKey": "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
	"unconfirmedSignature": 0,
	"secondSignature": 0,
	"secondPublicKey": null,
	"multisignatures": [
	],
	"u_multisignatures": [
	]
}
*/
