//
//  NodeKeychainDTO.swift
//
//
//  Created by Andrew G on 28.07.2024.
//

import Foundation

public struct NodeKeychainDTO: Codable {
    public let mainOrigin: NodeOrigin
    public let altOrigin: NodeOrigin?
    public let wsEnabled: Bool
    public let isEnabled: Bool
    public let version: String?
    public let height: Int?
    public let ping: TimeInterval?
    public let connectionStatus: NodeConnectionStatus?
    public let type: NodeType
}
