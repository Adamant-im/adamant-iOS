//
//  Node.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//
//  Check AdamantNodesMergingService when the structure is changed
//

import Foundation

public struct Node: Equatable, Identifiable, @unchecked Sendable {
    public let id: UUID
    public var mainOrigin: NodeOrigin
    public var altOrigin: NodeOrigin?
    public var wsEnabled: Bool
    public var version: Version?
    public var height: Int?
    public var ping: TimeInterval?
    public var connectionStatus: NodeConnectionStatus?
    public var preferMainOrigin: Bool?
    public var isEnabled: Bool
    public var type: NodeType

    public init(
        id: UUID,
        isEnabled: Bool,
        wsEnabled: Bool,
        mainOrigin: NodeOrigin,
        altOrigin: NodeOrigin?,
        version: Version?,
        height: Int?,
        ping: TimeInterval?,
        connectionStatus: NodeConnectionStatus?,
        preferMainOrigin: Bool?,
        type: NodeType
    ) {
        self.id = id
        self.mainOrigin = mainOrigin
        self.altOrigin = altOrigin
        self.isEnabled = isEnabled
        self.wsEnabled = wsEnabled
        self.version = version
        self.height = height
        self.ping = ping
        self.connectionStatus = connectionStatus
        self.preferMainOrigin = preferMainOrigin
        self.type = type
    }
}

extension Node {
    public var preferredOrigin: NodeOrigin {
        preferMainOrigin ?? true
            ? mainOrigin
            : altOrigin ?? mainOrigin
    }

    public static func makeDefaultNode(url: URL, altUrl: URL? = nil) -> Self {
        .init(
            id: .init(),
            isEnabled: true,
            wsEnabled: false,
            mainOrigin: .init(url: url),
            altOrigin: altUrl.map { .init(url: $0) },
            version: nil,
            height: nil,
            ping: nil,
            connectionStatus: nil,
            preferMainOrigin: nil,
            type: .default(isHidden: false)
        )
    }

    public func asSocketURL() -> URL? {
        preferredOrigin.asSocketURL()
    }

    public func asURL() -> URL? {
        preferredOrigin.asURL()
    }

    public func isSame(_ node: Node) -> Bool {
        mainOrigin.host == node.mainOrigin.host
    }

    public mutating func updateWsPort(_ wsPort: Int?) {
        mainOrigin.wsPort = wsPort
        altOrigin?.wsPort = wsPort
    }
}
