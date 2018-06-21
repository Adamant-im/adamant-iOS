//
//  Node.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum URLScheme: String {
	case http, https
}

struct Node: Equatable {
	let scheme: URLScheme
	let host: String
	let port: Int?
	
	func toString() -> String {
		if let port = port {
			return "\(scheme):\\\\\(host):\(port)"
		} else {
			return "\(scheme):\\\\\(host)"
		}
	}
}
