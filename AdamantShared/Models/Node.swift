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
    struct Status: Equatable, Codable {
        let ping: TimeInterval
        let wsEnabled: Bool
        let height: Int?
        let version: String?
    }
    
    enum ConnectionStatus: Equatable, Codable {
        case offline
        case synchronizing
        case allowed
    }
    
    static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.scheme == rhs.scheme
            && lhs.host == rhs.host
            && lhs.port == rhs.port
            && lhs.status == rhs.status
            && lhs.isEnabled == rhs.isEnabled
            && lhs._connectionStatus == rhs._connectionStatus
    }
    
    init(scheme: URLScheme, host: String, port: Int?) {
        self.scheme = scheme
        self.host = host
        self.port = port
    }
    
    init(url: URL) {
        let schemeRaw = url.scheme ?? "https"
        self.scheme = URLScheme(rawValue: schemeRaw) ?? .https
        self.host = url.host ?? ""
        self.port = url.port
    }
    
    var scheme: URLScheme
    var host: String
    var port: Int?
    var wsPort: Int?
    
    var status: Status?
    var isEnabled = true
    
    private var _connectionStatus: ConnectionStatus?
    
    var connectionStatus: ConnectionStatus? {
        get { isEnabled ? _connectionStatus : nil }
        set { _connectionStatus = newValue }
    }
    
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
        return asURL(forcePort: false, useWsPort: true)
    }
    
    func asURL() -> URL? {
        return asURL(forcePort: true)
    }
    
    private func asURL(forcePort: Bool, useWsPort: Bool = false) -> URL? {
        var components = URLComponents()
        components.scheme = scheme.rawValue
        components.host = host
        
        let usePort = useWsPort ? wsPort : port
        
        if let port = usePort, scheme == .http {
            components.port = port
        } else if forcePort {
            components.port = usePort ?? scheme.defaultPort
        }
        
        return components.url
    }
}
