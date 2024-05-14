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
            Node(url: URL(string: "https://ipfs1test.adamant.im")!),
            Node(url: URL(string: "https://ipfs2test.adamant.im")!),
            Node(url: URL(string: "https://ipfs3test.adamant.im")!)
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
