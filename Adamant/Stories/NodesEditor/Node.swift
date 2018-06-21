//
//  Node.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum NodeProtocol: String {
	case http, https
}

struct Node: Equatable {
	let `protocol`: NodeProtocol
	let url: String
	let port: Int?
	
	func toString() -> String {
		if let port = port {
			return "\(`protocol`):\\\\\(url):\(port)"
		} else {
			return "\(`protocol`):\\\\\(url)"
		}
	}
}
