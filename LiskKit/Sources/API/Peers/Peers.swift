//
//  Peers.swift
//  Lisk
//
//  Created by Andrew Barba on 1/8/18.
//

import Foundation

public struct Peers: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - List

extension Peers {

    /// List peers
    public func peers(ip: String? = nil, state: PeerModel.State? = nil, version: String? = nil, os: String? = nil, height: Int? = nil, limit: UInt? = nil, offset: UInt? = nil, sort: APIRequest.Sort? = nil, completionHandler: @escaping (Response<PeersResponse>) -> Void) {
        var options: RequestOptions = [:]
        if let value = ip { options["ip"] = value }
        if let value = state?.rawValue { options["state"] = value }
        if let value = version { options["version"] = value }
        if let value = os { options["os"] = value }
        if let value = height { options["height"] = value }
        if let value = limit { options["limit"] = value }
        if let value = offset { options["offset"] = value }
        if let value = sort?.value { options["sort"] = value }

        client.get(path: "peers", options: options, completionHandler: completionHandler)
    }
}
