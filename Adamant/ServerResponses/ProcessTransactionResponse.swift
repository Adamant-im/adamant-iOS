//
//  ProcessTransactionResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct ProcessTransactionResponse {
	let success: Bool
	let error: String?
	
	// TODO: Process correct transaction
}

extension ProcessTransactionResponse: Decodable {
	enum CodingKeys: String, CodingKey {
		case success, error
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.success = try container.decode(Bool.self, forKey: .success)
		self.error = try? container.decode(String.self, forKey: .error)
	}
}

// MARK: - JSON
/*
{
	"success": false,
	"error": "Account does not have enough ADM: U123123123123 balance: 0.49"
}
*/
