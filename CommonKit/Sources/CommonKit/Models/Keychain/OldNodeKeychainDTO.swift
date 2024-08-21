//
//  OldNodeKeychainDTO.swift
//
//
//  Created by Andrew G on 01.08.2024.
//

import Foundation

// TODO: delete after a few updates. It's used for migration.
public struct OldNodeKeychainDTO: Codable {
    public let group: NodeGroup
    public let node: NodeData
}

public extension OldNodeKeychainDTO {
    struct NodeData: Codable {
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
}

public extension OldNodeKeychainDTO.NodeData {
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
    
    func mapToModernDto() -> NodeKeychainDTO {
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
            connectionStatus: connectionStatus?.map(),
            type: oldDefaultHosts.contains(host)
                ? .default(isHidden: false)
                : .custom
        )
    }
}

private extension OldNodeKeychainDTO.NodeData.URLScheme {
    func map() -> NodeOrigin.URLScheme {
        switch self {
        case .http:
            return .http
        case .https:
            return .https
        }
    }
}

private extension OldNodeKeychainDTO.NodeData.ConnectionStatus {
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

private extension OldNodeKeychainDTO.NodeData.RejectedReason {
    func map() -> NodeConnectionStatus.RejectedReason {
        switch self {
        case .outdatedApiVersion:
            return .outdatedApiVersion
        }
    }
}

private let oldDefaultHosts: [String] = [
    "btcnode1.adamant.im",
    "btcnode3.adamant.im",
    "ethnode2.adamant.im",
    "ethnode3.adamant.im",
    "klyservice1.adamant.im",
    "klyservice2.adamant.im",
    "dogenode1.adamant.im",
    "dogenode2.adamant.im",
    "dashnode1.adamant.im",
    "dashnode2.adamant.im",
    "clown.adamant.im",
    "lake.adamant.im",
    "endless.adamant.im",
    "bid.adamant.im",
    "unusual.adamant.im",
    "debate.adamant.im",
    "78.47.205.206",
    "5.161.53.74",
    "184.94.215.92",
    "node1.adamant.business",
    "node2.blockchain2fa.io",
    "phecda.adm.im",
    "tegmine.adm.im",
    "tauri.adm.im",
    "dschubba.adm.im",
    "klynode1.adamant.im",
    "klynode2.adamant.im"
]
