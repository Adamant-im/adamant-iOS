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

class Node: Equatable, Codable {
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.host == rhs.host && lhs.port == rhs.port && lhs.scheme == rhs.scheme
    }
    
    init(scheme: URLScheme, host: String, port: Int?) {
        self.scheme = scheme
        self.host = host
        self.port = port
    }
    
    var scheme: URLScheme
    var host: String
    var port: Int?
    
    var height: Int?
    var wsEnabled: Bool?
    var ping: TimeInterval?
    
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
    
    func asSocketURL() -> URL? {
        return asURL(forcePort: false)
    }
    
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
