//
//  IPFS+Constants.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import AdamantWalletsKit
import CommonKit
import Foundation

extension IPFSApiService {
    static var symbol: String {
        "IPFS"
    }
    
    static private var ipfsService: CoinInfoDTO.Service? {
        CoinInfoProvider.storage?["ADM"]?
            .services?
            .ipfsNode
    }
    
    static private var nodeThreshold: Int {
        return if let admIpfsThreshold = ipfsService?.healthCheck?.threshold {
            admIpfsThreshold / 1_000_000
        } else {
            6
        }
    }
    
    static private var normalUpdateInterval: TimeInterval {
        return if let admIpfsNormalUpdateInterval = ipfsService?.healthCheck?.normalUpdateInterval {
            TimeInterval(admIpfsNormalUpdateInterval / 1_000)
        } else {
            300
        }
    }
    
    static private var crucialUpdateInterval: TimeInterval {
        return if let admIpfsCrucialUpdateInterval = ipfsService?.healthCheck?.crucialUpdateInterval {
            TimeInterval(admIpfsCrucialUpdateInterval / 1_000)
        } else {
            30
        }
    }

    static var nodes: [Node] {
        return if let ipfsNodeList = ipfsService?.list {
            ipfsNodeList.compactMap {
                if let url = URL(string: $0.url) {
                    var altIp: URL? = nil
                    if let altIpUrl = $0.altIp {
                        altIp = URL(string: altIpUrl)
                    }
                    return Node.makeDefaultNode(url: url, altUrl: altIp)
                }
                return nil
            }
        } else {
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
    }

    static let healthCheckParameters = BlockchainHealthCheckParams(
        group: .ipfs,
        name: symbol,
        normalUpdateInterval: normalUpdateInterval,
        crucialUpdateInterval: crucialUpdateInterval,
        minNodeVersion: nil,
        nodeHeightEpsilon: nodeThreshold
    )
}
