//
//  NodeGroup.swift
//  
//
//  Created by Andrew G on 30.10.2023.
//

public enum NodeGroup: Codable, CaseIterable, Hashable, Sendable {
    case btc
    case eth
    case klyNode
    case klyService
    case doge
    case dash
    case adm
    case ipfs
    case infoService
}
