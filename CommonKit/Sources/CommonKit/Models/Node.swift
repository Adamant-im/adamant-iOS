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

final public class Node: Equatable {
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
    
    public init(
        scheme: URLScheme,
        host: String,
        port: Int? = nil,
        wsPort: Int? = nil,
        status: Status? = nil,
        isEnabled: Bool = true,
        connectionStatus: ConnectionStatus? = nil
    ) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.wsPort = wsPort
        self.status = status
        self.isEnabled = isEnabled
        self._connectionStatus = connectionStatus
    }
    
    public init(url: URL) {
        let schemeRaw = url.scheme ?? "https"
        self.scheme = URLScheme(rawValue: schemeRaw) ?? .https
        self.host = url.host ?? ""
        self.port = url.port
        self.isEnabled = true
    }
    
    public init(url: URL, altUrl: URL?) {
        let schemeRaw = url.scheme ?? "https"
        self.scheme = URLScheme(rawValue: schemeRaw) ?? .https
        self.host = url.host ?? ""
        self.port = url.port
        self.isEnabled = true
        self.altUrl = altUrl
    }
    
    @Atomic public var scheme: URLScheme
    @Atomic public var host: String
    @Atomic public var port: Int?
    @Atomic public var wsPort: Int?
    @Atomic public var status: Status?
    @Atomic public var isEnabled: Bool
    @Atomic public var altUrl: URL?
    
    @Atomic private var _connectionStatus: ConnectionStatus?
    
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

extension Node: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(scheme, forKey: .scheme)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(wsPort, forKey: .wsPort)
        try container.encode(status, forKey: .status)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(_connectionStatus, forKey: ._connectionStatus)
    }
}

extension Node: Decodable {
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.init(
            scheme: try container.decode(URLScheme.self, forKey: .scheme),
            host: try container.decode(String.self, forKey: .host),
            port: try? container.decode(Optional<Int>.self, forKey: .port),
            wsPort: try? container.decode(Optional<Int>.self, forKey: .wsPort),
            status: try? container.decode(Optional<Status>.self, forKey: .status),
            isEnabled: try container.decode(Bool.self, forKey: .isEnabled),
            connectionStatus: try? container.decode(
                Optional<ConnectionStatus>.self,
                forKey: ._connectionStatus
            )
        )
    }
}

private extension Node {
    enum CodingKeys: String, CodingKey {
        case scheme
        case host
        case port
        case wsPort
        case status
        case isEnabled
        case _connectionStatus
    }
}
