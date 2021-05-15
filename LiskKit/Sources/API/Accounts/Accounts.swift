//
//  Accounts.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import Foundation

/// Accounts - https://docs.lisk.io/docs/lisk-api-080-accounts
public struct Accounts: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - List

extension Accounts {

    /// Retrieve accounts
    public func accounts(address: String? = nil, publicKey: String? = nil, secondPublicKey: String? = nil, username: String? = nil, limit: Int? = nil, offset: Int? = nil, sort: APIRequest.Sort? = nil, completionHandler: @escaping (Response<AccountsResponse>) -> Void) {
        var options: RequestOptions = [:]
        if let value = address { options["address"] = value }
        if let value = publicKey { options["publicKey"] = value }
        if let value = secondPublicKey { options["secondPublicKey"] = value }
        if let value = username { options["username"] = value }
        if let value = limit { options["limit"] = value }
        if let value = offset { options["offset"] = value }
        if let value = sort?.value { options["sort"] = value }

        client.get(path: "accounts", options: options, completionHandler: completionHandler)
    }
}
