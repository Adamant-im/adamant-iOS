//
//  Node.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum URLScheme: String, Codable {
	case http, https
}

struct Node: Equatable, Codable {
	let scheme: URLScheme
	let host: String
	let port: Int?
	
	func asString() -> String {
		return asURL()?.absoluteString ?? host
	}
	
	func asURL() -> URL? {
		var components = URLComponents()
		components.scheme = scheme.rawValue
		components.host = host
		components.port = port
		
		return try? components.asURL()
	}
}
