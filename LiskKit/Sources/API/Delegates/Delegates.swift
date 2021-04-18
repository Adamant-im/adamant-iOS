//
//  Delegates.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import Foundation

public struct Delegates: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - List

extension Delegates {

    /// List delegate objects
    public func delegates(address: String? = nil, publicKey: String? = nil, secondPublicKey: String? = nil, username: String? = nil, search: String? = nil, limit: UInt? = nil, offset: UInt? = nil, sort: APIRequest.Sort? = nil, completionHandler: @escaping (Response<DelegatesResponse>) -> Void) {
        var options: RequestOptions = [:]
        if let value = address { options["address"] = value }
        if let value = publicKey { options["publicKey"] = value }
        if let value = secondPublicKey { options["secondPublicKey"] = value }
        if let value = username { options["username"] = value }
        if let value = search { options["search"] = value }
        if let value = limit { options["limit"] = value }
        if let value = offset { options["offset"] = value }
        if let value = sort?.value { options["sort"] = value }

        client.get(path: "delegates", options: options, completionHandler: completionHandler)
    }
}
