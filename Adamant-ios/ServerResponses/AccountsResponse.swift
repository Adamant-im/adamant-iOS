//
//  AccountsResponse.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AccountsResponse {
	let success: Bool
	let error: String?
	let account: Account?
}

extension AccountsResponse: Decodable {
	enum CodingKeys: String, CodingKey {
		case success, error, account
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.success = try container.decode(Bool.self, forKey: .success)
		self.error = try? container.decode(String.self, forKey: .error)
		self.account = try? container.decode(Account.self, forKey: .account)
	}
}


// MARK: - JSON
/*
{
	"success": true,
	"account": {
		"address": "U000",
		"unconfirmedBalance": "49000000",
		"balance": "49000000",
		"publicKey": "8000000000",
		"unconfirmedSignature": 0,
		"secondSignature": 0,
		"secondPublicKey": null,
		"multisignatures": [
		],
		"u_multisignatures": [
		]
	}
}
*/
