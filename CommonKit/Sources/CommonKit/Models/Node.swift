//
//  Node.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public enum URLScheme: String, Codable {
    case http, https
    
    public static let `default`: URLScheme = .https
    
    public var defaultPort: Int {
        switch self {
        case .http: return 36666
        case .https: return 443
        }
    }
}

final public class Node: Equatable, Codable {
    public struct Status: Equatable, Codable {
        public let ping: TimeInterval
        public let wsEnabled: Bool
        public let height: Int?
        public let version: String?
        
        public init(ping: TimeInterval, wsEnabled: Bool, height: Int?, version: String?) {
            self.ping = ping
            self.wsEnabled = wsEnabled
            self.height = height
            self.version = version
        }
    }
    
    public enum ConnectionStatus: Equatable, Codable {
        case offline
        case synchronizing
        case allowed
    }
    
    public static func == (lhs: Node, rhs: Node) -> Bool {
        lhs.scheme == rhs.scheme
            && lhs.host == rhs.host
            && lhs.port == rhs.port
            && lhs.status == rhs.status
            && lhs.isEnabled == rhs.isEnabled
            && lhs._connectionStatus == rhs._connectionStatus
    }
    
    public init(scheme: URLScheme, host: String, port: Int?) {
        self.scheme = scheme
        self.host = host
        self.port = port
    }
    
    public init(url: URL) {
        let schemeRaw = url.scheme ?? "https"
        self.scheme = URLScheme(rawValue: schemeRaw) ?? .https
        self.host = url.host ?? ""
        self.port = url.port
    }
    
    public var scheme: URLScheme
    public var host: String
    public var port: Int?
    public var wsPort: Int?
    
    public var status: Status?
    public var isEnabled = true
    
    private var _connectionStatus: ConnectionStatus?
    
    public var connectionStatus: ConnectionStatus? {
        get { isEnabled ? _connectionStatus : nil }
        set { _connectionStatus = newValue }
    }
    
    public func asString() -> String {
        if let url = asURL(forcePort: scheme != URLScheme.default) {
            return url.absoluteString
        } else {
            return host
        }
    }
    
    /// Builds URL, using specified port, or default scheme's port, if nil
    ///
    /// - Returns: URL, if no errors were thrown
    
    public func asSocketURL() -> URL? {
        return asURL(forcePort: false, useWsPort: true)
    }
    
    public func asURL() -> URL? {
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
