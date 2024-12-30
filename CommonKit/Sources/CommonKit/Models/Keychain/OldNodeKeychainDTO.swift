//
//  OldNodeKeychainDTO.swift
//
//
//  Created by Andrew G on 01.08.2024.
//

import Foundation

// TODO: delete after a few updates. It's used for migration.
struct OldNodeKeychainDTO: Codable {
    let group: NodeGroup
    let node: NodeData
}

extension OldNodeKeychainDTO {
    struct NodeData: Codable {
        let id: UUID
        let scheme: URLScheme
        let host: String
        let isEnabled: Bool
        let wsEnabled: Bool
        let port: Int?
        let wsPort: Int?
        let version: String?
        let height: Int?
        let ping: TimeInterval?
        let connectionStatus: ConnectionStatus?
    }
}

extension OldNodeKeychainDTO.NodeData {
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
    
    func mapToModernDto(group: NodeGroup) -> NodeKeychainDTO {
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
            type: oldDefaultAdmHosts.contains(host) || group != .adm
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
    func map() -> NodeConnectionStatusKeychainDTO {
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
    func map() -> NodeConnectionStatusKeychainDTO.RejectedReason {
        switch self {
        case .outdatedApiVersion:
            return .outdatedApiVersion
        }
    }
}

private let oldDefaultAdmHosts: [String] = [
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
    "dschubba.adm.im"
]
