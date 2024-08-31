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
    func statusString(showVersion: Bool, dateHeight: Bool) -> String? {
        guard
            isEnabled,
            let connectionStatus = connectionStatus
        else { return Strings.disabled }
        
        let statusTitle = switch connectionStatus {
        case .allowed:
            pingString
        case .synchronizing:
            Strings.synchronizing
        case .offline:
            Strings.offline
        case .notAllowed(let reason):
            reason.text
        }
        
        return [
            statusTitle,
            showVersion ? versionString : nil,
            dateHeight ? dateHeightString : heightString
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
    
    func indicatorString(isRest: Bool, isWs: Bool) -> String {
        let connections = [
            isRest ? preferredOrigin.scheme.rawValue : nil,
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
        case .offline, .notAllowed:
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
    
    var pingString: String? {
        guard let ping = ping else { return nil }
        return "\(Strings.ping): \(Int(ping * 1000)) \(Strings.milliseconds)"
    }
    
    var heightString: String? {
        height.map { " ❐ \(getFormattedHeight(from: $0))" }
    }
    
    var dateHeightString: String? {
        height.map { Date(timeIntervalSince1970: .init($0)).humanizedTime().string }
    }
    
    var versionString: String? {
        version.map { "(v\($0.string))" }
    }
    
    var numberFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = ","
        return numberFormatter
    }
    
    func getFormattedHeight(from height: Int) -> String {
        numberFormatter.string(from: Decimal(height)) ?? String(height)
    }
}
