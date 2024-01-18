//
//  Node.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public struct Node: Equatable, Codable, Identifiable {
    public let id: UUID
    public var scheme: URLScheme
    public var host: String
    public var isEnabled: Bool
    public var wsEnabled: Bool
    public var port: Int?
    public var wsPort: Int?
    public var version: String?
    public var height: Int?
    public var ping: TimeInterval?
    public var connectionStatus: ConnectionStatus?
    
    public init(
        id: UUID = .init(),
        scheme: URLScheme,
        host: String,
        isEnabled: Bool,
        wsEnabled: Bool,
        port: Int? = nil,
        wsPort: Int? = nil,
        version: String? = nil,
        height: Int? = nil,
        ping: TimeInterval? = nil,
        connectionStatus: ConnectionStatus? = nil
    ) {
        self.id = id
        self.scheme = scheme
        self.host = host
        self.isEnabled = isEnabled
        self.wsEnabled = wsEnabled
        self.port = port
        self.wsPort = wsPort
        self.version = version
        self.height = height
        self.ping = ping
        self.connectionStatus = connectionStatus
    }
}

public extension Node {
    enum ConnectionStatus: Equatable, Codable {
        case offline
        case synchronizing
        case allowed
        case notAllowed
    }
    
    enum URLScheme: String, Codable {
        case http, https

        public static let `default`: URLScheme = .https

        public var defaultPort: Int {
            switch self {
            case .http: return 36666
            case .https: return 443
            }
        }
    }
    
    init(url: URL, altUrl _: URL? = nil) {
        self.init(
            scheme: URLScheme(rawValue: url.scheme ?? .empty) ?? .https,
            host: url.host ?? .empty,
            isEnabled: true,
            wsEnabled: false,
            port: url.port
        )
    }
    
    func asString() -> String {
        if let url = asURL(forcePort: scheme != .https) {
            return url.absoluteString
        } else {
            return host
        }
    }
    
    func asSocketURL() -> URL? {
        asURL(forcePort: false, useWsPort: true)
    }

    func asURL() -> URL? {
        asURL(forcePort: true)
    }
}

private extension Node {
    func asURL(forcePort: Bool, useWsPort: Bool = false) -> URL? {
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
