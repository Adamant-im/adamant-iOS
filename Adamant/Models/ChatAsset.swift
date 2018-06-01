//
//  ChatAsset.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct ChatAsset: Codable {
	enum CodingKeys: String, CodingKey {
		case message, ownMessage = "own_message", type
	}
	
	let message: String
	let ownMessage: String
	let type: ChatType
}

/* JSON
"chat": {
	"message": "7b7b3802f1d081e10624a373628fd0ba57e9348a7bca196c7511b05403a10611e3b4cf8b37cb9858f7f52cd5",
	"own_message": "f4f7972f735997b4c2014d87cb491bb156f9cc4d0404cb9c",
	"type": 0
}
*/
