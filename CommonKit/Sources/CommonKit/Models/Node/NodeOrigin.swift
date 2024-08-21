//
//  NodeOrigin.swift
//
//
//  Created by Andrew G on 27.07.2024.
//

import Foundation

public struct NodeOrigin: Codable, Equatable {
    public var scheme: URLScheme
    public var host: String
    public var port: Int?
    public var wsPort: Int?
    
    public init(
        scheme: URLScheme,
        host: String,
        port: Int? = nil,
        wsPort: Int? = nil
    ) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.wsPort = wsPort
    }
}

public extension NodeOrigin {
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
    
    init(url: URL) {
        self.init(
            scheme: URLScheme(rawValue: url.scheme ?? .empty) ?? .https,
            host: url.host ?? .empty,
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

private extension NodeOrigin {
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
