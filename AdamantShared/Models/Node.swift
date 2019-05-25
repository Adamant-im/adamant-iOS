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
	
	static let `default`: URLScheme = .https
	
	var defaultPort: Int {
		switch self {
		case .http: return 36666
		case .https: return 443
		}
	}
}

struct Node: Equatable, Codable {
	let scheme: URLScheme
	let host: String
	let port: Int?
	
	func asString() -> String {
		if let url = asURL(forcePort: scheme != URLScheme.default) {
			return url.absoluteString
		} else {
			return host
		}
	}
	
	
	/// Builds URL, using specified port, or default scheme's port, if nil
	///
	/// - Returns: URL, if no errors were thrown
	func asURL() -> URL? {
		return asURL(forcePort: true)
	}
	
	private func asURL(forcePort: Bool) -> URL? {
		var components = URLComponents()
		components.scheme = scheme.rawValue
		components.host = host
		
		if let port = port {
			components.port = port
		} else if forcePort {
			components.port = port ?? scheme.defaultPort
		}
		
		return components.url
	}
}
