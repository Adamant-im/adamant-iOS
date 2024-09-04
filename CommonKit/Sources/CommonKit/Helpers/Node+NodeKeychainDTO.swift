//
//  Node+NodeDTO.swift
//
//
//  Created by Andrew G on 28.07.2024.
//

public extension Node {
    func mapToDto() -> NodeKeychainDTO {
        .init(
            mainOrigin: mainOrigin,
            altOrigin: altOrigin,
            wsEnabled: wsEnabled,
            isEnabled: isEnabled,
            version: version?.string,
            height: height,
            ping: ping,
            connectionStatus: connectionStatus,
            type: type
        )
    }
}

public extension NodeKeychainDTO {
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
            connectionStatus: connectionStatus,
            preferMainOrigin: nil,
            type: type
        )
    }
}
