//
//  NodeStatusInfo.swift
//  Adamant
//
//  Created by Andrew G on 01.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public struct NodeStatusInfo: Equatable {
    public let ping: TimeInterval
    public let height: Int
    public let wsEnabled: Bool
    public let wsPort: Int?
    public let version: Version?
    
    public init(
        ping: TimeInterval,
        height: Int,
        wsEnabled: Bool,
        wsPort: Int?,
        version: Version?
    ) {
        self.ping = ping
        self.height = height
        self.wsEnabled = wsEnabled
        self.wsPort = wsPort
        self.version = version
    }
}
