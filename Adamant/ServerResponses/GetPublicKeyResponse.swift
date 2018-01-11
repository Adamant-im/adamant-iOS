//
//  GetPublicKeyResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class GetPublicKeyResponse: ServerResponse {
	let publicKey: String?
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let success = try container.decode(Bool.self, forKey: .success)
		let error = try? container.decode(String.self, forKey: .error)
		self.publicKey = try? container.decode(String.self, forKey: CodingKeys.init(stringValue: "publicKey")!)
		
		super.init(success: success, error: error)
	}
}

// MARK: - JSON
/*
{
	"success": true,
	"publicKey": "asdasdasdasdasddasdasdasdasdasdfuckdfdsf"
}
*/
