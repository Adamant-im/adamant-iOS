//
//  NodeGroup.swift
//  
//
//  Created by Andrew G on 30.10.2023.
//

public enum NodeGroup: Codable, CaseIterable, Hashable {
    case btc
    case eth
    case lskNode
    case lskService
    case doge
    case dash
    case adm
}

public extension NodeGroup {
    var name: String {
        switch self {
        case .btc:
            return "BTC"
        case .eth:
            return "ETH"
        case .lskNode, .lskService:
            return "LSK"
        case .doge:
            return "DOGE"
        case .dash:
            return "DASH"
        case .adm:
            return "ADM"
        }
    }
}
