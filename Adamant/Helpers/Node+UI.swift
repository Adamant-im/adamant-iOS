//
//  Node+UI.swift
//  Adamant
//
//  Created by Andrew G on 20.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import UIKit

extension Node {
    func statusString(showVersion: Bool) -> String? {
        guard isEnabled else { return Strings.disabled }
        
        switch connectionStatus {
        case .allowed:
            return [
                pingString,
                showVersion ? versionString : nil,
                heightString
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        case .synchronizing:
            return [
                Strings.synchronizing,
                showVersion ? versionString : nil,
                heightString
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        case .offline:
            return Strings.offline
        case .none:
            return nil
        }
    }
    
    func indicatorString(isRest: Bool, isWs: Bool) -> String {
        let connections = [
            isRest ? scheme.rawValue : nil,
            isWs ? "ws" : nil
        ].compactMap { $0 }
        
        return [
            "●",
            connections.isEmpty
                ? nil
                : connections.joined(separator: ", ")
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
    
    var indicatorColor: UIColor {
        guard isEnabled else { return .adamant.inactive }
        
        switch connectionStatus {
        case .allowed:
            return .adamant.good
        case .synchronizing:
            return .adamant.alert
        case .offline:
            return .adamant.danger
        case .none:
            return .adamant.inactive
        }
    }
}

private extension Node {
    enum Strings {
        static var ping: String {
            String.localized(
                "NodesList.NodeCell.Ping",
                comment: "NodesList.NodeCell: Node ping"
            )
        }
        
        static var milliseconds: String {
            String.localized(
                "NodesList.NodeCell.Milliseconds",
                comment: "NodesList.NodeCell: Milliseconds"
            )
        }
        
        static var synchronizing: String {
            String.localized(
                "NodesList.NodeCell.Synchronizing",
                comment: "NodesList.NodeCell: Node is synchronizing"
            )
        }
        
        static var offline: String {
            String.localized(
                "NodesList.NodeCell.Offline",
                comment: "NodesList.NodeCell: Node is offline"
            )
        }
        
        static var version: String {
            String.localized(
                "NodesList.NodeCell.Version",
                comment: "NodesList.NodeCell: Node version"
            )
        }
        
        static var disabled: String {
            String.localized(
                "NodesList.NodeCell.Disabled",
                comment: "NodesList.NodeCell: Node is disabled"
            )
        }
    }
    
    var versionString: String? {
        version.map { "(\(Strings.version): \($0))" }
    }
    
    var pingString: String? {
        guard let ping = ping else { return nil }
        return "\(Strings.ping): \(Int(ping * 1000)) \(Strings.milliseconds)"
    }
    
    var heightString: String? {
        height.map { "▱ \($0)" }
    }
}
