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
    func statusString(showVersion: Bool, includeVersionTitle: Bool = true) -> String? {
        guard isEnabled else { return Strings.disabled }
        
        switch connectionStatus {
        case .allowed:
            return [
                pingString,
                showVersion ? versionString(includeVersionTitle: includeVersionTitle) : nil,
                heightString
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        case .synchronizing:
            return [
                Strings.synchronizing,
                showVersion ? versionString(includeVersionTitle: includeVersionTitle) : nil,
                heightString
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        case .offline:
            return Strings.offline
        case .notAllowed(let reason):
            return [
                reason.text,
                version
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        case .none:
            return nil
        }
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
    
    var numberFormatter: NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = ","
        return numberFormatter
    }
    
    func getFormattedHeight(from height: Int) -> String {
        numberFormatter.string(from: Decimal(height)) ?? String(height)
    }
    
    func versionString(includeVersionTitle: Bool) -> String? {
        guard includeVersionTitle else {
            return version.map { "(\($0))" }
        }
        
        return version.map { "(v\($0))" }
    }
}

extension Node {
    static func stringToDouble(_ value: String?) -> Double? {
        guard let minNodeVersion = value?.replacingOccurrences(of: ".", with: ""),
              let versionNumber = Double(minNodeVersion)
        else { return nil }
        
        return versionNumber
    }
}
