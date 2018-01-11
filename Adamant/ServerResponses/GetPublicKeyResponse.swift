//
//  GetPublicKeyResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct GetPublicKeyResponse {
	let success: Bool
	let error: String?
	let publicKey: String?
}

extension GetPublicKeyResponse: Decodable {
	enum CodingKeys: String, CodingKey {
		case success, error, publicKey
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		self.success = try container.decode(Bool.self, forKey: .success)
		self.error = try? container.decode(String.self, forKey: .error)
		self.publicKey = try? container.decode(String.self, forKey: .publicKey)
	}
}

// MARK: - JSON
/*
{
	"success": true,
	"publicKey": "asdasdasdasdasddasdasdasdasdasdfuckdfdsf"
}
*/
