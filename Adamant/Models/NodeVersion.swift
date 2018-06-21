//
//  NodeVersion.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct NodeVersion: Codable {
	let success: Bool
	let build: String
	let commit: String
	let version: String
}

/* JSON

{
	"success": true,
	"build": "",
	"commit": "7abb065fed19045733b61e0e836c3179009a294b",
	"version": "0.3.0"
}

*/
