//
//  StateAsset.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct StateAsset: Codable {
	let key: String
	let value: String
	let type: StateType
}

/* JSON
"state": {
	"value": "myValue",
	"key": "myKey",
	"type": 0
}
*/
