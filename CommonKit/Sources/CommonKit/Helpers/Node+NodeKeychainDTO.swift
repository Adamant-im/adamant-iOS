//
//  Node+NodeDTO.swift
//
//
//  Created by Andrew G on 28.07.2024.
//

extension Node {
    func mapToDto() -> NodeKeychainDTO {
        .init(
            mainOrigin: mainOrigin,
            altOrigin: altOrigin,
            wsEnabled: wsEnabled,
            isEnabled: isEnabled,
            version: version?.string,
            height: height,
            ping: ping,
            connectionStatus: connectionStatus?.mapToDto(),
            type: type
        )
    }
}

extension NodeKeychainDTO {
    func mapToModel() -> Node {
        .init(
            id: .init(),
            isEnabled: isEnabled,
            wsEnabled: wsEnabled,
            mainOrigin: mainOrigin,
            altOrigin: altOrigin,
            version: version.flatMap { .init($0) },
            height: height,
            ping: ping,
            connectionStatus: connectionStatus?.mapToModel(),
            preferMainOrigin: nil,
            type: type
        )
    }
}

extension NodeConnectionStatus {
    func mapToDto() -> NodeConnectionStatusKeychainDTO {
        switch self {
        case .offline:
            .offline
        case .synchronizing:
            .synchronizing
        case .allowed:
            .allowed
        case let .notAllowed(rejectedReason):
            .notAllowed(rejectedReason.mapToDto())
        }
    }
}

extension NodeConnectionStatus.RejectedReason {
    func mapToDto() -> NodeConnectionStatusKeychainDTO.RejectedReason {
        switch self {
        case .outdatedApiVersion:
            .outdatedApiVersion
        }
    }
}

extension NodeConnectionStatusKeychainDTO {
    func mapToModel() -> NodeConnectionStatus {
        switch self {
        case .offline:
            .offline
        case .synchronizing:
            .synchronizing(isFinal: true)
        case .allowed:
            .allowed
        case let .notAllowed(rejectedReason):
            .notAllowed(rejectedReason.mapToModel())
        }
    }
}

extension NodeConnectionStatusKeychainDTO.RejectedReason {
    func mapToModel() -> NodeConnectionStatus.RejectedReason {
        switch self {
        case .outdatedApiVersion:
            .outdatedApiVersion
        }
    }
}
