//
//  Node.swift
//  Lisk
//
//  Created by Andrew Barba on 12/27/17.
//

import Foundation

public struct Node: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - Constants

extension Node {

    /// Retrieve the constants of a Lisk Node
    public func constants(completionHandler: @escaping (Response<NodeConstantsResponse>) -> Void) {
        client.get(path: "node/constants", completionHandler: completionHandler)
    }
}

// MARK: - Status

extension Node {

    /// Retrieve the status of a Lisk Node
    public func info() async throws -> NodeInfoModel {
        try await client.request(method: "system_getNodeInfo", params: [:])
    }
}
