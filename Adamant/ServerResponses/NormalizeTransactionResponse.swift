//
//  NormalizeTransactionResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct NormalizeTransactionResponse {
	let success: Bool
	let error: String?
	
	let normalizedTransaction: NormalizedTransaction?
}

extension NormalizeTransactionResponse: Decodable {
	enum CodingKeys: String, CodingKey {
		case success, error, transaction
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.success = try container.decode(Bool.self, forKey: .success)
		self.error = try? container.decode(String.self, forKey: .error)
		self.normalizedTransaction = try? container.decode(NormalizedTransaction.self, forKey: .transaction)
	}
}

// MARK: - JSON
/*
{
	"success": true,
	"transaction": {
		"type": 0,
		"amount": 50505050505,
		"senderPublicKey": "8007a01493bb4b21ec67265769898eb19514d9427bd7b701f96bc9880a6e209f",
		"requesterPublicKey": null,
		"timestamp": 11236791,
		"asset": {
		},
		"recipientId": "U2279741505997340299"
	}
}
*/
