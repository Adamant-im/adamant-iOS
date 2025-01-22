//
//  IPFSApiCore.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

extension IPFSApiCommands {
    static let status = "/api/node/info"
}

final class IPFSApiCore: Sendable {
    let apiCore: APICoreProtocol
    
    init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
    
    func getNodeStatus(origin: NodeOrigin) async -> ApiServiceResult<IPFSNodeStatus> {
        await apiCore.sendRequestJsonResponse(
            origin: origin,
            path: IPFSApiCommands.status
        )
    }
}

extension IPFSApiCore: BlockchainHealthCheckableService {
    func getStatusInfo(origin: NodeOrigin) async -> ApiServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        let statusResponse = await getNodeStatus(origin: origin)
        let ping = Date.now.timeIntervalSince1970 - startTimestamp
        
        return statusResponse.map { data in
            return .init(
                ping: ping,
                height: getHeightFrom(timestamp: data.timestamp),
                wsEnabled: false,
                wsPort: nil,
                version: getVersionFrom(stringVersion: data.version)
            )
        }
    }
    
    private func getHeightFrom(timestamp: UInt64) -> Int {
        let timeStampInSeconds = String(timestamp / 1000)
        
        /// Chicking the len of string representation of a timestamp in seconds
        /// to cut first two symbols from it and convert it to height
        if timeStampInSeconds.count >= 2 {
            let subString = timeStampInSeconds[
                timeStampInSeconds.index(timeStampInSeconds.startIndex, offsetBy: 2)..<timeStampInSeconds.endIndex
            ]
            let string = String(subString)
            return Int(string) ?? .zero
        } else {
            return .zero
        }
    }
    
    private func getVersionFrom(stringVersion: String) -> Version? {
        .init(stringVersion)
    }
}
