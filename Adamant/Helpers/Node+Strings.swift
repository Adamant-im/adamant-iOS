//
//  Node+Strings.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit

extension Node {
    func statusString(_ status: Node.ConnectionStatus?) -> String? {
        switch status {
        case .allowed:
            let ping = ping.map { Int($0 * 1000) }
            return ping.map { "\(NodeCell.Strings.ping): \($0) \(NodeCell.Strings.milliseconds)" }
        case .synchronizing:
            return NodeCell.Strings.synchronizing
        case .offline:
            return NodeCell.Strings.offline
        case .none:
            return nil
        }
    }
    
    var versionString: String? {
        version.map { "(\(NodeCell.Strings.version): \($0))" }
    }
}

private extension NodeCell {
    enum Strings {
        static let ping = String.localized(
            "NodesList.NodeCell.Ping",
            comment: "NodesList.NodeCell: Node ping"
        )
        
        static let milliseconds = String.localized(
            "NodesList.NodeCell.Milliseconds",
            comment: "NodesList.NodeCell: Milliseconds"
        )
        
        static let synchronizing = String.localized(
            "NodesList.NodeCell.Synchronizing",
            comment: "NodesList.NodeCell: Node is synchronizing"
        )
        
        static let offline = String.localized(
            "NodesList.NodeCell.Offline",
            comment: "NodesList.NodeCell: Node is offline"
        )
        
        static let version = String.localized(
            "NodesList.NodeCell.Version",
            comment: "NodesList.NodeCell: Node version"
        )
    }
}
