//
//  NodeConnectionStatus.swift
//
//
//  Created by Andrew G on 28.07.2024.
//

import Foundation

public enum NodeConnectionStatus: Equatable, Codable, Sendable {
    case offline
    case synchronizing(isFinal: Bool)
    case allowed
    case notAllowed(RejectedReason)
}

extension NodeConnectionStatus {
    public enum RejectedReason: Codable, Equatable, Sendable {
        case outdatedApiVersion
    }
}

extension NodeConnectionStatus.RejectedReason {
    public var text: String {
        switch self {
        case .outdatedApiVersion:
            return String.localized(
                "NodesList.NodeCell.Outdated",
                comment: "NodesList.NodeCell: Node is outdated"
            )
        }
    }
}
