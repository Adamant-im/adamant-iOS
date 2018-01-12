//
//  Account.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct Account: Codable {
	let address: String
	var unconfirmedBalance: UInt
	var balance: UInt
	let publicKey: String
	let unconfirmedSignature: Int
	let secondSignature: Int
	let secondPublicKey: String?
}

extension Account: WrappableModel {
	static let ModelKey = "account"
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
