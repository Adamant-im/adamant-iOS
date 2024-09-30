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
    var chosenFastestNodeId: UUID? {
        service.chosenFastestNodeId
    }
    
    var hasActiveNode: Bool {
        !service.sortedAllowedNodes.isEmpty
    }
    
    func healthCheck() {
        service.healthCheck()
    }
    
    static var symbol: String {
        "IPFS"
    }
    
    static var nodes: [Node] {
        [
            Node.makeDefaultNode(
                url: URL(string: "https://ipfs4.adm.im")!,
                altUrl: URL(string: "http://95.216.45.88:44099")!
            ),
            Node.makeDefaultNode(
                url: URL(string: "https://ipfs5.adamant.im")!,
                altUrl: URL(string: "http://62.72.43.99:44099")!
            ),
            Node.makeDefaultNode(
                url: URL(string: "https://ipfs6.adamant.business")!,
                altUrl: URL(string: "http://75.119.138.235:44099")!
            )
        ]
    }
    
    static let healthCheckParameters = BlockchainHealthCheckParams(
        group: .ipfs,
        name: symbol,
        normalUpdateInterval: 300,
        crucialUpdateInterval: 30,
        minNodeVersion: nil,
        nodeHeightEpsilon: 1
    )
}
