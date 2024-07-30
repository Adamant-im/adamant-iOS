//
//  Node+NodeDTO.swift
//
//
//  Created by Andrew G on 28.07.2024.
//

public extension Node {
    func mapToDto() -> NodeDTO {
        .init(
            mainOrigin: mainOrigin,
            altOrigin: altOrigin,
            wsEnabled: wsEnabled,
            isEnabled: isEnabled,
            version: version,
            height: height,
            ping: ping,
            connectionStatus: connectionStatus
        )
    }
}

public extension NodeDTO {
    func mapToModel() -> Node {
        .init(
            id: .init(),
            isEnabled: isEnabled,
            wsEnabled: wsEnabled,
            mainOrigin: mainOrigin,
            altOrigin: altOrigin,
            version: version,
            height: height,
            ping: ping,
            connectionStatus: connectionStatus,
            preferMainOrigin: nil
        )
    }
}
