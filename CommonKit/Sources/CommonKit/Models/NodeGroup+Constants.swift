//
//  NodeGroup+Constants.swift
//  
//
//  Created by Andrew G on 18.11.2023.
//

import Foundation

public extension NodeGroup {
    var defaultFastestNodeMode: Bool {
        switch self {
        case .adm:
            return false
        case .eth, .lskNode, .lskService, .doge, .dash, .btc, .ipfs:
            return true
        }
    }
}
