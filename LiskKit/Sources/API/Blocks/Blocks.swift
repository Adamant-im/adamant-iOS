//
//  Blocks.swift
//  Lisk
//
//  Created by Andrew Barba on 1/9/18.
//

import Foundation

public struct Blocks: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - List

extension Blocks {

    /// List blocks
    public func blocks(id: String? = nil, height: Int? = nil, generatorPublicKey: String? = nil, limit: Int? = nil, offset: Int? = nil, sort: APIRequest.Sort? = nil, completionHandler: @escaping (Response<BlocksResponse>) -> Void) {
        var options: RequestOptions = [:]
        if let value = id { options["blockId"] = value }
        if let value = height { options["height"] = value }
        if let value = generatorPublicKey { options["generatorPublicKey"] = value }
        if let value = limit { options["limit"] = value }
        if let value = offset { options["offset"] = value }
        if let value = sort?.value { options["sort"] = value }

        client.get(path: "blocks", options: options, completionHandler: completionHandler)
    }
}
