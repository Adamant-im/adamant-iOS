//
//  ProcessTransactionResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class TransactionIdResponse: ServerResponse {
	let transactionId: UInt64?
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let success = try container.decode(Bool.self, forKey: .success)
		let error = try? container.decode(String.self, forKey: .error)
		
		if let idRaw = try? container.decode(String.self, forKey: CodingKeys(stringValue: "transactionId")!) {
			transactionId = UInt64(idRaw)
		} else {
			transactionId = nil
		}
		
		super.init(success: success, error: error)
	}
}

// MARK: - JSON
/*
{
	"success": true,
	"transactionId": "8888888888888888888"
}
*/
