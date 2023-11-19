//
//  NodeGroup+Constants.swift
//  
//
//  Created by Andrew G on 18.11.2023.
//

import Foundation

public extension NodeGroup {
    var nodeHeightEpsilon: Int {
        switch self {
        case .adm:
            return 10
        case .btc:
            return 2
        case .eth:
            return 5
        case .lskService, .lskNode:
            return 5
        case .doge:
            return 3
        case .dash:
            return 3
        }
    }
    
    var normalUpdateInterval: TimeInterval {
        switch self {
        case .adm:
            return 300000
        case .btc:
            return 360000
        case .eth:
            return 300000
        case .lskNode:
            return 270000
        case .lskService:
            return 330000
        case .doge:
            return 390000
        case .dash:
            return 210000
        }
    }
    
    var crucialUpdateInterval: TimeInterval {
        30
    }
    
    var defaultFastestNodeMode: Bool {
        switch self {
        case .adm:
            return false
        case .eth, .lskNode, .lskService, .doge, .dash, .btc:
            return true
        }
    }
}
