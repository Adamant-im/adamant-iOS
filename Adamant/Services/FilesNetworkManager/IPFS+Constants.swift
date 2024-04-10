//
//  IPFS+Constants.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension IPFSApiService {
    var preferredNodeIds: [UUID] {
        service.preferredNodeIds
    }
    
    func healthCheck() {
        service.healthCheck()
    }
    
    static var symbol: String {
        "IPFS"
    }
    
    static var nodes: [Node] {
        [
            Node(url: URL(string: "http://194.163.154.252:4000")!),
            Node(url: URL(string: "http://154.26.159.245:4000")!),
            Node(url: URL(string: "http://109.123.240.102:4000")!)
        ]
    }
    
    static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: 210,
        crucialUpdateInterval: 30,
        onScreenUpdateInterval: 10,
        threshold: 3,
        normalServiceUpdateInterval: 210,
        crucialServiceUpdateInterval: 30,
        onScreenServiceUpdateInterval: 10
    )
}
