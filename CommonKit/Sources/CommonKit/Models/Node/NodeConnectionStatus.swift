//
//  NodeConnectionStatus.swift
//
//
//  Created by Andrew G on 28.07.2024.
//

import Foundation

public indirect enum NodeConnectionStatus: Equatable, Codable {
    case offline
    case synchronizing
    case allowed
    case notAllowed(RejectedReason)
    case requesting(NodeConnectionStatus?)
    case processing(NodeConnectionStatus?)
}

public extension NodeConnectionStatus {
    enum RejectedReason: Codable, Equatable {
        case outdatedApiVersion
    }
}

public extension NodeConnectionStatus.RejectedReason {
    var text: String {
        switch self {
        case .outdatedApiVersion:
            return String.localized(
                "NodesList.NodeCell.Outdated",
                comment: "NodesList.NodeCell: Node is outdated"
            )
        }
    }
}
