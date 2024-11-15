//
//  NodesKeychainDTO.swift
//
//
//  Created by Andrew G on 05.09.2024.
//

import Foundation

struct NodesKeychainDTO: Codable {
    let version: String
    let data: SafeDecodingDictionary<NodeGroup, SafeDecodingArray<NodeKeychainDTO>>
    
    init(_ data: [NodeGroup: [NodeKeychainDTO]]) {
        self.version = "1.0.0"
        self.data = .init(data.mapValues { .init($0) })
    }
}

struct NodeKeychainDTO: Codable {
    let mainOrigin: NodeOrigin
    let altOrigin: NodeOrigin?
    let wsEnabled: Bool
    let isEnabled: Bool
    let version: String?
    let height: Int?
    let ping: TimeInterval?
    let connectionStatus: NodeConnectionStatusKeychainDTO?
    let type: NodeType
}

enum NodeConnectionStatusKeychainDTO: Equatable, Codable, Sendable {
    case offline
    case synchronizing
    case allowed
    case notAllowed(RejectedReason)
}

extension NodeConnectionStatusKeychainDTO {
    enum RejectedReason: Codable, Equatable, Sendable {
        case outdatedApiVersion
    }
}
