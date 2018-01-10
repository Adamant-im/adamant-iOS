//
//  TransactionsResponse.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct TransactionsResponse {
	let success: Bool
	let transactions: [Transaction]?
	let count: Int
	let error: String?
}

extension TransactionsResponse: Decodable {
	enum CodingKeys: String, CodingKey {
		case success, transactions, count, error
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.success = try container.decode(Bool.self, forKey: .success)
		self.transactions = try? container.decode([Transaction].self, forKey: .transactions)
		self.error = try? container.decode(String.self, forKey: .error)
		
		if let count = try? container.decode(Int.self, forKey: .count) {
			self.count = count
		} else {
			self.count = 0
		}
		
	}
}


// MARK: - JSON
/*
{
	"success": true,
	"transactions": [
	{
	"id": "1873173140086400619",
	"height": 777336,
	"blockId": "10172499053153614044",
	"type": 0,
	"timestamp": 10724447,
	"senderPublicKey": "cdab95b082b9774bd975677c868261618c7ce7bea97d02e0f56d483e30c077b6",
	"senderId": "U15423595369615486571",
	"recipientId": "U2279741505997340299",
	"recipientPublicKey": "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
	"amount": 49000000,
	"fee": 50000000,
	"signature": "539f80c8a71abc8d4d31e5bd0d0ddb1ea98499c1d43fe5ab07faec8d376cd12357cf17bca36dc7a561085cbd615e64c523f2b17807d3f4da787baaa657aa450a",
	"signatures": [
	],
	"confirmations": 67431,
	"asset": {
	}
	}
	],
	"count": "1"
}
*/
