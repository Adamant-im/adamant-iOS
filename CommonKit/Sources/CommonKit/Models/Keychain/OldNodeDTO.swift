//
//  OldNodeDTO.swift
//
//
//  Created by Andrew G on 30.07.2024.
//

import Foundation

// TODO: Remove after a few updates (it's used for migration)
public struct OldNodeDTO: Codable {
    public let id: UUID
    public let scheme: URLScheme
    public let host: String
    public let isEnabled: Bool
    public let wsEnabled: Bool
    public let port: Int?
    public let wsPort: Int?
    public let version: String?
    public let height: Int?
    public let ping: TimeInterval?
    public let connectionStatus: ConnectionStatus?
}

public extension OldNodeDTO {
    enum RejectedReason: Codable, Equatable {
        case outdatedApiVersion
    }
    
    enum ConnectionStatus: Equatable, Codable {
        case offline
        case synchronizing
        case allowed
        case notAllowed(RejectedReason)
    }
    
    enum URLScheme: String, Codable {
        case http
        case https
    }
    
    func mapToModernDto() -> NodeDTO {
        .init(
            mainOrigin: .init(
                scheme: scheme.map(),
                host: host,
                port: port,
                wsPort: wsPort
            ),
            altOrigin: nil,
            wsEnabled: wsEnabled,
            isEnabled: isEnabled,
            version: version,
            height: height,
            ping: ping,
            connectionStatus: connectionStatus?.map()
        )
    }
}

private extension OldNodeDTO.URLScheme {
    func map() -> NodeOrigin.URLScheme {
        switch self {
        case .http:
            return .http
        case .https:
            return .https
        }
    }
}

private extension OldNodeDTO.ConnectionStatus {
    func map() -> NodeConnectionStatus {
        switch self {
        case .offline:
            return .offline
        case .synchronizing:
            return .synchronizing
        case .allowed:
            return .allowed
        case let .notAllowed(reason):
            return .notAllowed(reason.map())
        }
    }
}

private extension OldNodeDTO.RejectedReason {
    func map() -> NodeConnectionStatus.RejectedReason {
        switch self {
        case .outdatedApiVersion:
            return .outdatedApiVersion
        }
    }
}
