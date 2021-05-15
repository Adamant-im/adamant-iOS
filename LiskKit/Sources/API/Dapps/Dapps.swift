//
//  Dapps.swift
//  Lisk
//
//  Created by Andrew Barba on 4/11/18.
//

import Foundation

public struct Dapps: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - List

extension Dapps {

    /// List Dapps
    public func blocks(transactionId: String? = nil, name: Int? = nil, limit: Int? = nil, offset: Int? = nil, sort: APIRequest.Sort? = nil, completionHandler: @escaping (Response<DappsResponse>) -> Void) {
        var options: RequestOptions = [:]
        if let value = transactionId { options["transactionId"] = value }
        if let value = name { options["name"] = value }
        if let value = limit { options["limit"] = value }
        if let value = offset { options["offset"] = value }
        if let value = sort?.value { options["sort"] = value }

        client.get(path: "dapps", options: options, completionHandler: completionHandler)
    }
}
