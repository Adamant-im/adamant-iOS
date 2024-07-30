//
//  Node.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public struct Node: Equatable, Identifiable {
    public let id: UUID
    public var mainOrigin: NodeOrigin
    public var altOrigin: NodeOrigin?
    public var wsEnabled: Bool
    public var version: String?
    public var height: Int?
    public var ping: TimeInterval?
    public var connectionStatus: NodeConnectionStatus?
    public var preferMainOrigin: Bool?
    
    public var isEnabled: Bool {
        didSet {
            guard !isEnabled else { return }
            connectionStatus = nil
        }
    }
    
    public init(
        id: UUID,
        isEnabled: Bool,
        wsEnabled: Bool,
        mainOrigin: NodeOrigin,
        altOrigin: NodeOrigin?,
        version: String?,
        height: Int?,
        ping: TimeInterval?,
        connectionStatus: NodeConnectionStatus?,
        preferMainOrigin: Bool?
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
    }
}

public extension Node {
    var preferredOrigin: NodeOrigin {
        preferMainOrigin ?? true
            ? mainOrigin
            : altOrigin ?? mainOrigin
    }

    init(url: URL, altUrl: URL? = nil) {
        self.init(
            id: .init(),
            isEnabled: true,
            wsEnabled: false,
            mainOrigin: .init(url: url),
            altOrigin: altUrl.map { .init(url: $0) },
            version: nil,
            height: nil,
            ping: nil,
            connectionStatus: nil,
            preferMainOrigin: nil
        )
    }
    
    func asString() -> String {
        preferredOrigin.asString()
    }
    
    func asSocketURL() -> URL? {
        preferredOrigin.asSocketURL()
    }

    func asURL() -> URL? {
        preferredOrigin.asURL()
    }
    
    mutating func updateWsPort(_ wsPort: Int?) {
        mainOrigin.wsPort = wsPort
        altOrigin?.wsPort = wsPort
    }
}
