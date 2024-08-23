//
//  BlockchainHealthCheckParams.swift
//
//
//  Created by Andrew G on 08.08.2024.
//

import Foundation

public struct BlockchainHealthCheckParams {
    public let group: NodeGroup
    public let name: String
    public let normalUpdateInterval: TimeInterval
    public let crucialUpdateInterval: TimeInterval
    public let minNodeVersion: Version?
    public let nodeHeightEpsilon: Int
    
    public init(
        group: NodeGroup,
        name: String,
        normalUpdateInterval: TimeInterval,
        crucialUpdateInterval: TimeInterval,
        minNodeVersion: Version?,
        nodeHeightEpsilon: Int
    ) {
        self.group = group
        self.name = name
        self.normalUpdateInterval = normalUpdateInterval
        self.crucialUpdateInterval = crucialUpdateInterval
        self.minNodeVersion = minNodeVersion
        self.nodeHeightEpsilon = nodeHeightEpsilon
    }
}
